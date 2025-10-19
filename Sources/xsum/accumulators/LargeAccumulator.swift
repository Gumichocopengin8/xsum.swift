struct LargeAccumulator: ~Copyable {
    var m_chunk: [UInt64]  // Chunks making up large accumulator
    var m_count: [Int32]  // Counts of # adds remaining for chunks, or -1 if not used yet or special
    var m_chunks_used: [UInt64]  // Bits indicate chunks in use
    var m_used_used: UInt64  // Bits indicate chunk_used entries not 0
    var m_sacc: SmallAccumulator  // The small accumulator to condense into

    init() {
        self.m_chunk = Array(repeating: 0, count: XSUM_LCHUNKS)
        self.m_count = Array(repeating: -1, count: XSUM_LCHUNKS)
        self.m_chunks_used = Array(repeating: 0, count: XSUM_LCHUNKS / 64)
        self.m_used_used = 0
        self.m_sacc = SmallAccumulator()
    }

    mutating func add_lchunk_to_small(ix: Int) {
        let count: Int32 = self.m_count[ix]

        // Add to the small accumulator only if the count is not -1, which
        // indicates a chunk that contains nothing yet.
        if count >= 0 {
            // Propagate carries in the small accumulator if necessary.
            if self.m_sacc.m_adds_until_propagate == 0 {
                let _ = self.m_sacc.carry_propagate()
            }

            // Get the chunk we will add.  Note that this chunk is the integer sum
            // of entire 64-bit floating-point representations, with sign, exponent,
            // and mantissa, but we want only the sum of the mantissas.
            var chunk = self.m_chunk[ix]

            // If we added the maximum number of values to 'chunk', the sum of
            // the sign and exponent parts (all the same, equal to the index) will
            // have overflowed out the top, leaving only the sum of the mantissas.
            // If the count of how many more terms we could have summed is greater
            // than zero, we therefore add this count times the index (shifted to
            // the position of the sign and exponent) to get the unwanted bits to
            // overflow out the top.
            if count > 0 {
                chunk = chunk &+ ((UInt64(count) &* UInt64(ix)) &<< XSUM_MANTISSA_BITS)
            }

            // Find the exponent for this chunk from the low bits of the index,
            // and split it into low and high parts, for accessing the small
            // accumulator.  Noting that for denormalized numbers where the
            // exponent part is zero, the actual exponent is 1 (before subtracting
            // the bias), not zero.
            let exp: Int32 = Int32(ix) & Int32(XSUM_EXP_MASK)
            var low_exp: Int32 = exp & Int32(XSUM_LOW_EXP_MASK)
            var high_exp = Int(exp >> XSUM_LOW_EXP_BITS)
            if exp == 0 {
                low_exp = 1
                high_exp = 0
            }

            // Split the mantissa into three parts, for three consecutive chunks in
            // the small accumulator.  Except for denormalized numbers, add in the sum
            // of all the implicit 1 bits that are above the actual mantissa bits.
            let low_chunk: Int64 =
                Int64(truncatingIfNeeded: chunk << low_exp) & XSUM_LOW_MANTISSA_MASK
            var mid_chunk: Int64 = Int64(chunk) >> (XSUM_LOW_MANTISSA_BITS - Int64(low_exp))
            if exp != 0 {
                // normalized
                mid_chunk +=
                    (Int64(1 << XSUM_LCOUNT_BITS) - Int64(count))
                    << (XSUM_MANTISSA_BITS - XSUM_LOW_MANTISSA_BITS + Int64(low_exp))
            }
            let high_chunk = mid_chunk >> XSUM_LOW_MANTISSA_BITS
            mid_chunk &= XSUM_LOW_MANTISSA_MASK

            // Add or subtract the three parts of the mantissa from three small
            // accumulator chunks, according to the sign that is part of the index.
            if ix & (1 << XSUM_EXP_BITS) != 0 {
                self.m_sacc.m_chunk[high_exp] -= low_chunk
                self.m_sacc.m_chunk[high_exp + 1] -= mid_chunk
                self.m_sacc.m_chunk[high_exp + 2] -= high_chunk
            } else {
                self.m_sacc.m_chunk[high_exp] += low_chunk
                self.m_sacc.m_chunk[high_exp + 1] += mid_chunk
                self.m_sacc.m_chunk[high_exp + 2] += high_chunk
            }

            // The above additions/subtractions reduce by one the number we can
            // do before we need to do carry propagation again.
            self.m_sacc.m_adds_until_propagate -= 1
        }

        // We now clear the chunk to zero, and set the count to the number
        // of adds we can do before the mantissa would overflow.  We also
        // set the bit in chunks_used to indicate that this chunk is in use
        // (if that is enabled).
        self.m_chunk[ix] = 0
        self.m_count[ix] = 1 << XSUM_LCOUNT_BITS
        self.m_chunks_used[ix >> 6] |= 1 << (ix & 0x3f)
        self.m_used_used |= 1 << (ix >> 6)
    }

    mutating func large_add_value_inf_nan(ix: Int, uintv: UInt64) {
        if (Int64(ix) & XSUM_EXP_MASK) == XSUM_EXP_MASK {
            self.m_sacc.add_inf_nan(ivalue: Int64(truncatingIfNeeded: uintv))
        } else {
            self.add_lchunk_to_small(ix: ix)
            self.m_count[ix] -= 1
            self.m_chunk[ix] += uintv
        }
    }

    mutating func transfer_to_small() {
        let chunks_used_size = self.m_chunks_used.count
        var p: Int = 0

        // Very quickly skip some unused low-order blocks of chunks by looking
        // at the m_usedUsed flags.
        var uu = self.m_used_used
        if (uu & 0xffff_ffff) == 0 {
            uu >>= 32
            p += 32
        }
        if (uu & 0xffff) == 0 {
            uu >>= 16
            p += 16
        }
        if (uu & 0xff) == 0 {
            p += 8
        }

        // Loop over remaining blocks of chunks.
        var u: UInt64
        while true {
            // Loop to quickly find the next non-zero block of used flags,
            // or finish up if we've added all the used blocks to the small accumulator.
            while true {
                u = self.m_chunks_used[p]
                if u != 0 {
                    break
                }
                p += 1
                if p == chunks_used_size {
                    return
                }
                u = self.m_chunks_used[p]
                if u != 0 {
                    break
                }
                p += 1
                if p == chunks_used_size {
                    return
                }
                u = self.m_chunks_used[p]
                if u != 0 {
                    break
                }
                p += 1
                if p == chunks_used_size {
                    return
                }
                u = self.m_chunks_used[p]
                if u != 0 {
                    break
                }
                p += 1
                if p == chunks_used_size {
                    return
                }
            }

            // Find and process the chunks in this block that are used.  We skip
            // forward based on the m_chunksUsed flags until we're within eight
            // bits of a chunk that is in use.
            var ix: Int = p << 6
            if (u & 0xffff_ffff) == 0 {
                u >>= 32
                ix += 32
            }
            if (u & 0xffff) == 0 {
                u >>= 16
                ix += 16
            }
            if (u & 0xff) == 0 {
                u >>= 8
                ix += 8
            }

            while true {
                if self.m_count[ix] >= 0 {
                    self.add_lchunk_to_small(ix: ix)
                }
                ix += 1
                u >>= 1
                if u == 0 {
                    break
                }
            }
            p += 1
            if p >= chunks_used_size {
                break
            }
        }
    }
}
