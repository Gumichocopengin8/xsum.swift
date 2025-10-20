# Xsum in Swift

This package implments xsum algorithm by Radford M. Neal (https://arxiv.org/abs/1505.05571).

xsum is able to calculate fast exact summation.

> [!NOTE]
> Currently, xsum supports `Double` calculation only.

## Xsum Types

- `XsumSmall`: Optimized for arrays with up to 1,000 elements.
- `XsumLarge`: Optimized for arrays with more than 1,000 elements.
- `XsumAuto`: Automatically selects the appropriate variant when the array size is unknown.
- `XsumVariant`: Provides a convenient interface for managing multiple Xsum structs.

> [!TIP]
> `XsumAuto` internally uses `XsumSmall` and `XsumLarge`.
> `XsumAuto` has runtime overhead to determine when to switch from `XsumSmall` to `XsumLarge`.
> If you already know the input size in advance, consider using `XsumVariant` instead to avoid this overhead.


## Usage

### `addList()` to take array

Calculates the sum of a small-sized array.

```swift
import Xsum

var xsmall = XsumSmall()
xsmall.addList([1.0, 2.0, 3.0])
assert(xsmall.sum() == 6.0)
```

Calculates the sum of a large-sized array (more than 1,000 elements).

```swift
import Xsum

var xlarge = XsumLarge()
xlarge.addList(Array(repeating: 1.0, count: 1_500))
assert(xlarge.sum() == 1_500.0)
```

Calculates the sum of a unknown-sized array.

```swift
import Xsum

var xauto = XsumAuto()
xauto.addList(Array(repeating: 1.0, count: 1_500))
assert(xauto.sum() == 1_500.0)
```

### `add()` to take a floating point number

```swift
import Xsum

var xsmall = XsumSmall()
let arr = [1.0, 2.0, 3.0]
for v in arr {
    xsmall.add(v)
}
assert(xsmall.sum() == 6.0)
```

### Chaining Method

```swift
import Xsum

let arr = [1.0, 2.0, 3.0]
assert(arr.xsum() == 6.0)
```

### Variant

If you already know the input size in advance, you can directly select the
most suitable xsum variant, avoiding unnecessary overhead.

```swift
import Xsum

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

## Comformance

xsum comforms to Javascript's [Math.sumPrecise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/sumPrecise) behavior.
