/// `XsumVariant` provides an easy way to manage multiple xsum variants.
///
/// This is useful when you want to adjust behavior based on the input size.
/// For example, `XsumAuto` can automatically choose the appropriate xsum variant,
/// which is useful when the input size is unknown.
/// However, it has some overhead to determine when to switch from `XsumSmall` to `XsumLarge`.
///
/// If you already know the input size in advance, you can directly select the
/// most suitable xsum variant, avoiding unnecessary overhead.
public enum XsumVariant: ~Copyable, Xsum {
    case small(XsumSmall)
    case large(XsumLarge)
    case auto(XsumAuto)

    public init() {
        self = .small(XsumSmall())
    }

    public mutating func addList(_ arr: [Double]) {
        switch self {
        case .small(var xsumSmall):
            xsumSmall.addList(arr)
            self = .small(xsumSmall)
        case .large(var xsumLarge):
            xsumLarge.addList(arr)
            self = .large(xsumLarge)
        case .auto(var xsumAuto):
            xsumAuto.addList(arr)
            self = .auto(xsumAuto)
        }
    }

    public mutating func add(_ value: Double) {
        switch self {
        case .small(var xsumSmall):
            xsumSmall.add(value)
            self = .small(xsumSmall)
        case .large(var xsumLarge):
            xsumLarge.add(value)
            self = .large(xsumLarge)
        case .auto(var xsumAuto):
            xsumAuto.add(value)
            self = .auto(xsumAuto)
        }
    }

    public mutating func sum() -> Double {
        switch self {
        case .small(var xsumSmall):
            let result = xsumSmall.sum()
            self = .small(xsumSmall)
            return result
        case .large(var xsumLarge):
            let result = xsumLarge.sum()
            self = .large(xsumLarge)
            return result
        case .auto(var xsumAuto):
            let result = xsumAuto.sum()
            self = .auto(xsumAuto)
            return result
        }
    }

    public mutating func clear() {
        switch self {
        case .small(var xsumSmall):
            xsumSmall.clear()
            self = .small(xsumSmall)
        case .large(var xsumLarge):
            xsumLarge.clear()
            self = .large(xsumLarge)
        case .auto(var xsumAuto):
            xsumAuto.clear()
            self = .auto(xsumAuto)
        }
    }
}
