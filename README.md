# Xsum in Swift

This crate implments xsum algorithm by Radford M. Neal (https://arxiv.org/abs/1505.05571).

xsum is able to calculate fast exact summation.

> [!NOTE]
> Currently, xsum supports `Double` calculation only.

## Usage

### `addList()` to take vector or array

Calculates the sum of a small-sized vector or array.

```swift
var xsmall = XsumSmall()
xsmall.addList([1.0, 2.0, 3.0])
assert(xsmall.sum() == 6.0)
```

Calculates the sum of a large-sized vector or array (more than 1,000 elements).

```swift
var xlarge = XsumLarge()
xlarge.addList(Array(repeating: 1.0, count: 1_500))
assert(xlarge.sum() == 1_500.0)
```

Calculates the sum of a unknown-sized vector or array.

```swift
var xauto = XsumAuto()
xauto.addList(Array(repeating: 1.0, count: 1_500))
assert(xauto.sum() == 1_500.0)
```

### `add()` to take a floating point number

```swift
var xsmall = XsumSmall()
let arr = [1.0, 2.0, 3.0]
for v in arr {
    xsmall.add(v)
}
assert(xsmall.sum() == 6.0)
```

### Chaining Method

```swift
let arr = [1.0, 2.0, 3.0]
assert(arr.xsum() == 6.0)
```

### Variant

If you already know the input size in advance, you can directly select the
most suitable xsum variant, avoiding unnecessary overhead.

```swift
let arr = Array(repeating: 1.0, count: 2_000)
var xVariant: XsumVariant =
    if arr.count < XSUM_THRESHOLD {
        .small(XsumSmall())
    } else {
        .large(XsumLarge())
    }
xVariant.addList(arr)
assert(xVariant.sum() == 2_000.0)
```
