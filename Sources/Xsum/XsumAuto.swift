enum XsumKind: ~Copyable {
  // TODO: https://forums.swift.org/t/how-do-you-switch-on-a-noncopyable-type/65136
  // As of swift v6.2, switch statement always consumes variable, so use `empty` case to avoid the issue
  // when switch can borrow variable in the future, get rid of it, and rewrite each method more concisely like xsum.rs
  case empty
  case small(XsumSmall)
  case large(XsumLarge)
}

/// XsumAuto is efficient if vector or array size is unknown
///
/// It automatically select either XsumSmall or XsumLarge based on the number of added value
///
/// If the size if less than or equal to 1,000, use XsumSmall, otherwise, use XsumLarge
public struct XsumAuto: ~Copyable, Xsum {
  private var m_xsum: XsumKind

  public init() {
    self.m_xsum = XsumKind.small(XsumSmall())
  }

  public mutating func addList(_ vec: [Double]) {
    var old = XsumKind.empty
    swap(&old, &self.m_xsum)

    switch old {
    case .small(var xsmall):
      xsmall.addList(vec)
      self.m_xsum = .small(xsmall)
      self.transformToLarge()
    case .large(var xlarge):
      xlarge.addList(vec)
      self.m_xsum = .large(xlarge)
    case .empty:
      fatalError("Empty case should never occur")
    }
  }

  public mutating func add(_ value: Double) {
    var old = XsumKind.empty
    swap(&old, &self.m_xsum)

    switch old {
    case .small(var xsmall):
      xsmall.add(value)
      self.m_xsum = .small(xsmall)
      self.transformToLarge()
    case .large(var xlarge):
      xlarge.add(value)
      self.m_xsum = .large(xlarge)
    case .empty:
      fatalError("Empty case should never occur")
    }
  }

  public mutating func sum() -> Double {
    var old = XsumKind.empty
    swap(&old, &self.m_xsum)

    switch old {
    case .small(var xsmall):
      let result = xsmall.sum()
      self.m_xsum = .small(xsmall)
      return result
    case .large(var xlarge):
      let result = xlarge.sum()
      self.m_xsum = .large(xlarge)
      return result
    case .empty:
      fatalError("Empty case should never occur")
    }
  }

  public mutating func clear() {
    self = .init()
  }

  private mutating func transformToLarge() {
    let should_transform =
      switch self.m_xsum {
      case .small(let xsmall):
        xsmall.getSizeCount() > XSUM_THRESHOLD
      case .large:
        false
      case .empty:
        fatalError("Empty case should never occur")
      }

    if !should_transform {
      return
    }

    var old_xsum = XsumKind.empty
    swap(&old_xsum, &self.m_xsum)

    if case .small(let xsmall) = old_xsum {
      self.m_xsum = .large(XsumLarge.fromXsumSmall(xsmall: xsmall))
    }
  }
}
