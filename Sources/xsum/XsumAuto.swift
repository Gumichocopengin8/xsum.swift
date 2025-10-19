enum XsumKind: ~Copyable {
  // TODO: https://forums.swift.org/t/how-do-you-switch-on-a-noncopyable-type/65136
  // As of swift v6.2, switch statement always consumes variable, so use `empty` case to avoid the issue
  // when switch can borrow variable in the future, get rid of it, and rewrite each method more concisely like xsum.rs
  case Empty
  case XSmall(XsumSmall)
  case XLarge(XsumLarge)
}

/// XsumAuto is efficient if vector or array size is unknown
///
/// It automatically select either XsumSmall or XsumLarge based on the number of added value
///
/// If the size if less than or equal to 1,000, use XsumSmall, otherwise, use XsumLarge
struct XsumAuto: ~Copyable, Xsum {
  var m_xsum: XsumKind

  init() {
    self.m_xsum = XsumKind.XSmall(XsumSmall())
  }

  mutating func add_list(vec: [Double]) {
    var old = XsumKind.Empty
    swap(&old, &self.m_xsum)

    switch old {
    case .XSmall(var xsmall):
      xsmall.add_list(vec: vec)
      self.m_xsum = .XSmall(xsmall)
      self.transform_to_large()
    case .XLarge(var xlarge):
      xlarge.add_list(vec: vec)
      self.m_xsum = .XLarge(xlarge)
    case .Empty:
      fatalError("Empty case should never occur")
    }
  }

  mutating func add(value: Double) {
    var old = XsumKind.Empty
    swap(&old, &self.m_xsum)

    switch old {
    case .XSmall(var xsmall):
      xsmall.add(value: value)
      self.m_xsum = .XSmall(xsmall)
      self.transform_to_large()
    case .XLarge(var xlarge):
      xlarge.add(value: value)
      self.m_xsum = .XLarge(xlarge)
    case .Empty:
      fatalError("Empty case should never occur")
    }
  }

  mutating func sum() -> Double {
    var old = XsumKind.Empty
    swap(&old, &self.m_xsum)

    switch old {
    case .XSmall(var xsmall):
      let result = xsmall.sum()
      self.m_xsum = .XSmall(xsmall)
      return result
    case .XLarge(var xlarge):
      let result = xlarge.sum()
      self.m_xsum = .XLarge(xlarge)
      return result
    case .Empty:
      fatalError("Empty case should never occur")
    }
  }

  mutating func clear() {
    self = .init()
  }

  mutating func transform_to_large() {
    let should_transform =
      switch self.m_xsum {
      case .XSmall(let xsmall):
        xsmall.get_size_count() > XSUM_THRESHOLD
      case .XLarge:
        false
      case .Empty:
        fatalError("Empty case should never occur")
      }

    if !should_transform {
      return
    }

    var old_xsum = XsumKind.Empty
    swap(&old_xsum, &self.m_xsum)

    if case .XSmall(let xsmall) = old_xsum {
      self.m_xsum = .XLarge(XsumLarge.from_xsum_small(xsmall: xsmall))
    }
  }
}
