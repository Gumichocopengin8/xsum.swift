struct SmallAccumulator: ~Copyable {
    var m_chunk: [Int64]  // Chunks making up small accumulator
    var m_addsUntilPropagate: Int64  // Number of remaining adds before carry
    var m_inf: Int64  // If non-zero, +Inf, -Inf, or NaN
    var m_nan: Int64  // If non-zero, a NaN value with payload
    var m_sizeCount: UInt64  // number of added values
    var m_hasPosNumber: Bool  // check if added values have at least one positive number

    init() {
        self.m_chunk = Array(repeating: 0, count: XSUM_SCHUNKS)
        self.m_addsUntilPropagate = XSUM_SMALL_CARRY_TERMS
        self.m_inf = 0
        self.m_nan = 0
        self.m_sizeCount = 0
        self.m_hasPosNumber = false
    }

    init(smallAccumulator: borrowing SmallAccumulator) {
        self.m_chunk = smallAccumulator.m_chunk
        self.m_addsUntilPropagate = smallAccumulator.m_addsUntilPropagate
        self.m_inf = smallAccumulator.m_inf
        self.m_nan = smallAccumulator.m_nan
        self.m_sizeCount = smallAccumulator.m_sizeCount
        self.m_hasPosNumber = smallAccumulator.m_hasPosNumber
    }

    mutating func carryPropagate() -> Int {
        // Set u to the index of the uppermost non-zero (for now) chunk, or
        // return with value 0 if there is none.
        var u: Int = XSUM_SCHUNKS - 1
        while 0 <= u && self.m_chunk[u] == 0 {
            if u == 0 {
                self.m_addsUntilPropagate = XSUM_SMALL_CARRY_TERMS - 1
                return 0
            }
            u -= 1
        }

        // At this point, m_chunk[u] must be non-zero
        assert(self.m_chunk[u] != 0, "m_chunk[u] must be non-zero")

        // Carry propagate, starting at the low-order chunks.  Note that the
        // loop limit of u may be increased inside the loop.
        var i: Int = 0  // set to the index of the next non-zero chunck, from bottom
        var uix: Int = -1  // indicates that a non-zero chunk has not been found yet

        while true {
            var c: Int64  // Set to the chunk at index i (next non-zero one)

            // Find the next non-zero chunk, setting i to its index, or break out
            // of loop if there is none.  Note that the chunk at index u is not
            // necessarily non-zero - it was initially, but u or the chunk at u
            // may have changed.
            while true {
                c = self.m_chunk[i]
                if c != 0 {
                    break
                }
                i += 1
                if i > u {
                    break
                }
            }

            if i > u {
                break
            }

            let chigh: Int64 = c >> XSUM_LOW_MANTISSA_BITS  // High-order bits of c
            if chigh == 0 {
                uix = i
                i += 1
                continue  // no need to change this chunk
            }

            if u == i {
                if chigh == -1 {
                    uix = i
                    break  // don't propagate -1 into the region of all zeros above
                }
                u = i + 1  // we will change chunk[u+1], so we'll need to look at it
            }

            let clow: Int64 = c & XSUM_LOW_MANTISSA_MASK  // Low-order bits of c
            if clow != 0 {
                uix = i
            }

            // We now change chunk[i] and add to chunk[i+1]. Note that i+1 should be
            // in range (no bigger than XSUM_CHUNKS-1) if summing memory, since
            // the number of chunks is big enough to hold any sum, and we do not
            // store redundant chunks with values 0 or -1 above previously non-zero
            // chunks.  But other add operations might cause overflow, in which
            // case we produce a NaN with all 1s as payload.  (We can't reliably produce
            // an Inf of the right sign.)

            self.m_chunk[i] = clow
            if i + 1 >= XSUM_SCHUNKS {
                self.addInfNan(ivalue: (XSUM_EXP_MASK << XSUM_MANTISSA_BITS) | XSUM_MANTISSA_MASK)
                u = i
            } else {
                self.m_chunk[(i + 1)] += chigh  // note: this could make this chunk be zero
            }

            i += 1

            if i > u {
                break
            }
        }

        // Check again for the number being zero, since carry propagation might
        // have created zero from something that initially looked non-zero.
        if uix < 0 {
            uix = 0
            self.m_addsUntilPropagate = XSUM_SMALL_CARRY_TERMS - 1
            return uix
        }

        // While the uppermost chunk is negative, with value -1, combine it with
        // the chunk below (if there is one) to produce the same number but with
        // one fewer non-zero chunks.
        while self.m_chunk[uix] == -1 && uix > 0 {
            // Left shift of a negative number is undefined according to the standard,
            // so do a multiply - it's all presumably constant-folded by the compiler.
            self.m_chunk[(uix - 1)] += -(1 << XSUM_LOW_MANTISSA_BITS)
            self.m_chunk[uix] = 0
            uix -= 1
        }

        self.m_addsUntilPropagate = XSUM_SMALL_CARRY_TERMS - 1
        return uix  // Return index of uppermost non-zero chunk
    }

    mutating func addInfNan(ivalue: Int64) {
        let mantissa: Int64 = ivalue & XSUM_MANTISSA_MASK

        if mantissa == 0 {
            // Inf
            if self.m_inf == 0 {
                // no previous Inf
                self.m_inf = ivalue
            } else if self.m_inf != ivalue {
                // previous Inf was opposite sign
                var fltv: Double = Double(bitPattern: UInt64(bitPattern: ivalue))
                fltv -= fltv  // result will be a NaN
                self.m_inf = Int64(bitPattern: fltv.bitPattern)
            }
        } else {
            // NaN
            // Choose the NaN with the bigger payload and clear its sign.
            // Using <= ensures that we will choose the first NaN over the previous zero.
            if (self.m_nan & XSUM_MANTISSA_MASK) <= mantissa {
                self.m_nan = ivalue & ~XSUM_SIGN_MASK
            }
        }
    }

    mutating func add1NoCarry(_ value: Double) {
        let ivalue = Int64(bitPattern: value.bitPattern)

        // Extract exponent and mantissa.  Split exponent into high and low parts.
        let exp: Int64 = (ivalue >> XSUM_MANTISSA_BITS) & XSUM_EXP_MASK
        var mantissa: Int64 = ivalue & XSUM_MANTISSA_MASK
        let highExp: Int = Int(exp >> XSUM_LOW_EXP_BITS)
        var lowExp: Int64 = exp & XSUM_LOW_EXP_MASK

        // Categorize number as normal, denormalized, or Inf/NaN according to
        // the value of the exponent field.
        if exp == 0 {
            // zero or denormalized
            // If it's a zero (positive or negative), we do nothing.
            if mantissa == 0 {
                return
            }
            // Denormalized mantissa has no implicit 1, but exponent is 1 not 0.
            lowExp = 1
        } else if exp == XSUM_EXP_MASK {
            // Inf or NaN
            // Just update flags in accumulator structure.
            self.addInfNan(ivalue: ivalue)
            return
        } else {
            // normalized
            // OR in implicit 1 bit at top of mantissa
            mantissa |= 1 << XSUM_MANTISSA_BITS
        }

        // Separate mantissa into two parts, after shifting, and add to (or
        // subtract from) this chunk and the next higher chunk (which always
        // exists since there are three extra ones at the top).

        // Note that low_mantissa will have at most XSUM_LOW_MANTISSA_BITS bits,
        // while high_mantissa will have at most XSUM_MANTISSA_BITS bits, since
        // even though the high mantissa includes the extra implicit 1 bit, it will
        // also be shifted right by at least one bit.
        let splitMantissaFirst: Int64 = (mantissa << lowExp) & XSUM_LOW_MANTISSA_MASK
        let splitMantissaSecond: Int64 = mantissa >> (XSUM_LOW_MANTISSA_BITS - lowExp)

        // Add to, or subtract from, the two affected chunks.
        if ivalue < 0 {
            self.m_chunk[highExp] -= splitMantissaFirst
            self.m_chunk[highExp + 1] -= splitMantissaSecond
        } else {
            self.m_chunk[highExp] += splitMantissaFirst
            self.m_chunk[highExp + 1] += splitMantissaSecond
        }
    }

    mutating func incrementWhenValueAdded(_ value: Double) {
        self.m_sizeCount += 1
        self.m_hasPosNumber = self.m_hasPosNumber || value.sign == .plus
    }
}
