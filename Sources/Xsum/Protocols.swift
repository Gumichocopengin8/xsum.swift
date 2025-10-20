protocol Xsum: ~Copyable {
    init()
    mutating func addList(_ arr: [Double])
    mutating func add(_ value: Double)
    mutating func sum() -> Double
    mutating func clear()
}
