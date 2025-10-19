protocol Xsum: ~Copyable {
  init()
  mutating func add_list(vec: [Double])
  mutating func add(value: Double)
  mutating func sum() -> Double
  mutating func clear()
}

/// XsumExt selects either XsumSmall or XsumLarge based on the number of elements of vector or array
///
/// If the size if less than or equal to 1,000, use XsumSmall, otherwise, use XsumLarge

// TODO: add extension

// protocol XsumExt {
//     func xsum() -> Double;
// }

// impl XsumExt for [f64] {
//     fn xsum(&self) -> f64 {
//         if self.len() < XSUM_THRESHOLD {
//             let mut xsumsmall = xsum_small::XsumSmall::new();
//             xsumsmall.add_list(self);
//             xsumsmall.sum()
//         } else {
//             let mut xsumlarge = xsum_large::XsumLarge::new();
//             xsumlarge.add_list(self);
//             xsumlarge.sum()
//         }
//     }
// }
