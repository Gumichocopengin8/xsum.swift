/// XsumLarge is efficient if vector or array size is more 1,000
struct XsumLarge: ~Copyable, Xsum {
  var m_lacc: LargeAccumulator

  init() {
    self.m_lacc = LargeAccumulator()
  }

  mutating func addList(_ vec: [Double]) {
    for value in vec {
      self.add(value)
    }
  }

  mutating func add(_ value: Double) {
    // increment
    self.m_lacc.m_sacc.incrementWhenValueAdded(value)

    // Convert to integer form in uintv
    let uintv: UInt64 = value.bitPattern

    // Isolate the upper sign+exponent bits that index the chunk.
    let ix: Int = Int(uintv >> XSUM_MANTISSA_BITS)

    // Find the count for this chunk, and subtract one.
    let count: Int32 = self.m_lacc.m_count[ix] - 1

    if count < 0 {
      // If the decremented count is negative, it's either a special
      // Inf/NaN chunk (in which case count will stay at -1), or one that
      // needs to be transferred to the small accumulator, or one that
      // has never been used before and needs to be initialized.
      self.m_lacc.largeAddValueInfNan(ix: ix, uintv: uintv)
    } else {
      // Store the decremented count of additions allowed before transfer,
      // and add this value to the chunk.
      self.m_lacc.m_count[ix] = count
      self.m_lacc.m_chunk[ix] = self.m_lacc.m_chunk[ix] &+ uintv
    }
  }

  mutating func sum() -> Double {
    self.m_lacc.transferToSmall()
    var xsum_smal = XsumSmall(smallAccumulator: self.m_lacc.m_sacc)
    return xsum_smal.sum()
  }

  mutating func clear() {
    self = .init()
  }

  static func fromXsumSmall(xsmall: consuming XsumSmall) -> Self {
    var lacc = LargeAccumulator()
    lacc.m_sacc = xsmall.transferAccumulator()
    var newLarge = Self()
    newLarge.m_lacc = lacc
    return newLarge
  }
}
