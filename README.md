# CombineOperators
[![CI Status](https://img.shields.io/travis/Voidilov/CombineOperators.svg?style=flat)](https://travis-ci.org/Voidilov/CombineOperators)
[![Version](https://img.shields.io/cocoapods/v/CombineOperators.svg?style=flat)](https://cocoapods.org/pods/CombineOperators)
[![License](https://img.shields.io/cocoapods/l/CombineOperators.svg?style=flat)](https://cocoapods.org/pods/CombineOperators)
[![Platform](https://img.shields.io/cocoapods/p/CombineOperators.svg?style=flat)](https://cocoapods.org/pods/CombineOperators)

## Description

This repo includes operators for Combine, almost complete re-implementation of RxCocoa, RxViewController, RxGestures and RxKeyboard libraries and some additional features.

Example

```swift
import UIKit
import Combine
import CombineCocoa
import CombineOperators

final class SomeViewModel {
  let title = CurrentValueSubject<String, Never>("Title")
  let icon = CurrentValueSubject<UIImage?, Never>(nil)
  let color = CurrentValueSubject<UIColor, Never>(UIColor.white)
  let bool = CurrentValueSubject<Bool, Never>(false)
  ...
} 

class ViewController: UIViewController {

  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var iconView: UIImageView!
  @IBOutlet private weak var switchView: UISwitch!

  let viewModel = SomeViewModel()
  ...
  private func configureSubscriptions() {
    viewModel.title ==> titleLabel.cb.text
    viewModel.iconView ==> iconView.cb.image
    viewModel.bool ==> switchView.cb.isOn
    viewModel.color ==> (self, ViewController.setTint)
    //or viewModel.color ==> cb.weak(method: ViewController.setTint)
    //or viewModel.color ==> {[weak self] in self?.setTint(color: $0) }
  }

  private func setTint(color: UIColor) {
  ...
  } 
  ...
}
```

## Usage

1. Operator `=>` 

- From `Publisher` to `Subscriber`, creates a subscription:
  
  ```swift
  intPublisher => intSubscriber
```

- From `Publisher` to `Subject`, creates a subscription and returns `Cancellable`:

```swift
  let Cancellable = intPublisher => intSubject
  ```

  - From `Cancellable` to `DisposeBag`:
  
  ```swift
  someCancellable => cancellableSet
  somePublisher => someSubject => cancellableSet
  ```
  
  - From `Publisher` to `Scheduler`, returns `AnyPublisher<Output, Failure>`:
  
  ```swift
  somePublisher => DispatchQueue.main => someSubscriber
  ```
  
  - From `Publisher` to `(Output) -> Void`:
  
  ```swift
  somePublisher => { print($0) }
  ```
  
  - From `Publisher` to `@autoescaping () -> Void`:
  
  ```swift
  somePublisher => print("action")
  ```
  All operators casts output-input types and errors types where possible
  
2. Operator `==>`
  
Drive `Publisher` to `Subscriber` on main queue:
```swift
intPublisher ==> intSubscriber => cancellableSet
```

3. Operators `=>>` and `==>>` replaces `.removeDublicates()`

4. `CancellableBuilder` and `MergeBuilder`, `CombineLatestBuilder` - result builders

5. Some features:
- `UIView.cb` operators: `isVisible`, `willAppear`, `isOnScreen`, `didAppear`, `movedToWindow`, `frame`, `frameOnWindow`, etc. 
- `skipNil()` operator
- `or(Bool), .toggle(), !` operators for boolean sequences
- use `+` and `+=` operator for merging publishers, creating Cancellables, etc
- `interval(...)` 
- `withLast() -> AnyPublisher<(previous: Output?, current: Output), Failure>`
- `.mp` - `@dynamicMemberLookup` mapper
- `asResult() -> AnyPublisher<Result<Output, Failure>, Never>`
- `nilIfEmpty`
- `isEmpty`
- `isNil`
- `isNilOrEmpty`
- `append(...)`
- `smooth(...)` methods to smooth changes, example: sequence`[0, 1]` turns to `[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]`
- `onValue, onFailure, onFinished, onSubscribe, onCancel, onRequest` wrappers on `handleEvents(...)` operator
- `guard()`
- `cb.isFirstResponder`
- `UIStackView().cb.update(...)`
- `UIView().cb.transform.scale(), .rotation(), .translation()`

## Installation

1.  [CocoaPods](https://cocoapods.org)

CombineOperators is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:
```ruby
pod 'CombineOperators/CombineCocoa'
```
and run `pod update` from the podfile directory first.

2. [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.
```swift
// swift-tools-version:5.0
import PackageDescription

let package = Package(
  name: "SomeProject",
  dependencies: [
    .package(url: "https://github.com/dankinsoid/CombineOperators.git", from: "1.41.0")
    ],
  targets: [
    .target(name: "SomeProject", dependencies: ["CombineOperators"])
    ]
)
```
```ruby
$ swift build
```
## Author

Voidilov, voidilov@gmail.com

## License

CombineOperators is available under the MIT license. See the LICENSE file for more info.
