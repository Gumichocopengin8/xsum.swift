protocol Xsum: ~Copyable {
  init()
  mutating func addList(_ vec: [Double])
  mutating func add(_ value: Double)
  mutating func sum() -> Double
  mutating func clear()
}
