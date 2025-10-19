/// `XsumVariant` provides an easy way to manage multiple xsum variants.
///
/// This is useful when you want to adjust behavior based on the input size.
/// For example, `XsumAuto` can automatically choose the appropriate xsum variant,
/// which is useful when the input size is unknown.
/// However, it has some overhead to determine when to switch from `XsumSmall` to `XsumLarge`.
///
/// If you already know the input size in advance, you can directly select the
/// most suitable xsum variant, avoiding unnecessary overhead.
enum XsumVariant: ~Copyable, Xsum {
  case small(XsumSmall)
  case large(XsumLarge)

  init() {
    self = .small(XsumSmall())
  }

  mutating func add_list(vec: [Double]) {
    switch self {
    case .small(var xsum_small):
      xsum_small.add_list(vec: vec)
      self = .small(xsum_small)
    case .large(var xsum_large):
      xsum_large.add_list(vec: vec)
      self = .large(xsum_large)
    }
  }

  mutating func add(value: Double) {
    switch self {
    case .small(var xsum_small):
      xsum_small.add(value: value)
      self = .small(xsum_small)
    case .large(var xsum_large):
      xsum_large.add(value: value)
      self = .large(xsum_large)
    }
  }

  mutating func sum() -> Double {
    switch self {
    case .small(var xsum_small):
      let result = xsum_small.sum()
      self = .small(xsum_small)
      return result
    case .large(var xsum_large):
      let result = xsum_large.sum()
      self = .large(xsum_large)
      return result
    }
  }

  mutating func clear() {
    switch self {
    case .small(var xsum_small):
      xsum_small.clear()
      self = .small(xsum_small)
    case .large(var xsum_large):
      xsum_large.clear()
      self = .large(xsum_large)
    }
  }
}
