// CONSTANTS DEFINING THE FLOATING POINT FORMAT
let XSUM_MANTISSA_BITS: Int64 = 52  // Bits in fp mantissa, excludes implict 1
let XSUM_EXP_BITS: Int64 = 11  // Bits in fp exponent
let XSUM_MANTISSA_MASK: Int64 = (1 << XSUM_MANTISSA_BITS) - 1  // Mask for mantissa bits
let XSUM_EXP_MASK: Int64 = (1 << XSUM_EXP_BITS) - 1  // Mask for exponent
let XSUM_EXP_BIAS: Int64 = (1 << (XSUM_EXP_BITS - 1)) - 1  // Bias added to signed exponent
let XSUM_SIGN_BIT: Int64 = XSUM_MANTISSA_BITS + XSUM_EXP_BITS  // Position of sign bit
let XSUM_SIGN_MASK: Int64 = 1 << XSUM_SIGN_BIT  // Mask for sign bit

// CONSTANTS DEFINING THE SMALL ACCUMULATOR FORMAT
let XSUM_SCHUNK_BITS: Int64 = 64  // Bits in chunk of the small accumulator
let XSUM_LOW_EXP_BITS: Int64 = 5  // # of low bits of exponent, in one chunk
let XSUM_LOW_EXP_MASK: Int64 = (1 << XSUM_LOW_EXP_BITS) - 1  // Mask for low-order exponent bits
let XSUM_HIGH_EXP_BITS: Int64 = XSUM_EXP_BITS - XSUM_LOW_EXP_BITS  // # of high exponent bits for index
let XSUM_SCHUNKS: Int = (1 << XSUM_HIGH_EXP_BITS) + 3  // # of chunks in small accumulator
let XSUM_LOW_MANTISSA_BITS: Int64 = 1 << XSUM_LOW_EXP_BITS  // Bits in low part of mantissa
let XSUM_LOW_MANTISSA_MASK: Int64 = (1 << XSUM_LOW_MANTISSA_BITS) - 1  // Mask for low bits
let XSUM_SMALL_CARRY_BITS: Int64 = (XSUM_SCHUNK_BITS - 1) - XSUM_MANTISSA_BITS  // Bits sums can carry into
let XSUM_SMALL_CARRY_TERMS: Int64 = (1 << XSUM_SMALL_CARRY_BITS) - 1  // # terms can add before need prop.

// CONSTANTS DEFINING THE LARGE ACCUMULATOR FORMAT
let XSUM_LCOUNT_BITS: Int64 = 64 - XSUM_MANTISSA_BITS  // # of bits in count
let XSUM_LCHUNKS: Int = 1 << (XSUM_EXP_BITS + 1)  // # of chunks in large accumulator

// Misc

/// The `XSUM_THRESHOLD` is used to determine whether an xsum is small or large, based on the number of inputs.
/// This is the default value, but you may use a different value if it works better.
public let XSUM_THRESHOLD: UInt64 = 1_000
