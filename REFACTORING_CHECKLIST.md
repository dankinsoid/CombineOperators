# CombineOperators Refactoring Checklist

This checklist tracks the refactoring progress for the CombineOperators repository.

## Legend
- [ ] Not started
- [🔄] In progress
- [✅] Complete

---

## 1. Project Structure

### 1.1 Directory Organization
- [✅] Review and optimize folder structure
- [ ] Consider splitting large iOS module if needed
- [ ] Add README files for each major module/folder
- [✅] Review naming conventions (e.g., `Dipsatch.swift` typo - FIXED)

---

## 2. CombineOperators Module

### 2.1 Core Operators
#### `Binder.swift`
- [✅] Review and enhance doc comments
- [✅] Add usage examples for both initializers
- [✅] Add code example for MainActor binding
- [✅] Write unit tests for Binder with weak references
- [✅] Write tests for scheduler-based binding
- [✅] Write tests for target deallocation scenarios

#### `Replay.swift`
- [✅] Add doc comments to ReplaySubject class
- [✅] Document ReplaySubjectSubscription
- [✅] Add examples for buffer size usage
- [✅] Write tests for ReplaySubject with various buffer sizes
- [✅] Test completion handling
- [✅] Test concurrent subscriptions
- [✅] Test late subscriber behavior

#### `Publisher++.swift`
- [✅] Add doc comments for each extension method
- [✅] Add examples for: `with(weak:)`, `silenсeFailure()`, `catch(_:)`, etc.
- [✅] Document operator chaining examples
- [ ] Write tests for weak reference operators
- [ ] Write tests for error handling operators
- [ ] Write tests for collection operators
- [ ] Write tests for custom operators (`+`, `??`, `&`, `!`)
- [ ] Test `AnyPublisher` static factory methods

#### `Subscriber++.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Cancellable++.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Create.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `OnDeinit.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Lock.swift`
- [✅] Add doc comments explaining the lock mechanism
- [✅] Add usage examples
- [ ] Write thread safety tests
- [ ] Performance tests

#### `MainScheduler.swift`
- [✅] Add doc comments
- [✅] Explain MainActor integration
- [✅] Add usage examples
- [ ] Write tests for main thread scheduling
- [ ] Test MainActor isolation

#### `MergeBuilder.swift`
- [✅] Add doc comments
- [✅] Add result builder usage examples
- [ ] Write tests for various merge scenarios

#### `Smooth.swift`
- [✅] Add doc comments explaining smoothing algorithm
- [✅] Add practical examples
- [ ] Write tests for smoothing behavior
- [ ] Edge case tests

### `Async.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests for async/await integration

### 2.2 Operators
#### `MainSchedulerOperator.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `RemoveDuplicatesMainSchedulerOperator.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `RemoveDuplicatesOperator.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `SubscribeOperator.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

### 2.3 Supporting Files
#### `CombineError.swift`
- [✅] Add doc comments
- [✅] Add usage examples (internal enum, cases self-explanatory)
- [ ] Write unit tests

#### `CombinePrecedence.swift`
- [✅] Add doc comments explaining precedence rules
- [✅] Add examples
- [ ] Write tests

#### `NSNotification++.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

---

## 3. CombineCocoa Module

### 3.1 Core Files
#### `CombineCocoa.swift`
- [✅] Review error enum documentation
- [✅] Add examples for error handling
- [✅] Document helper functions
- [✅] Write tests for error types
- [✅] Test casting functions

### 3.2 Common Infrastructure ✅ **COMPLETE** (8/8 files)
#### `Common/Reactive.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [✅] Write unit tests

#### `Common/ReactiveBinder.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Common/HasObserver.swift`
- [✅] Add doc comments
- [✅] Add usage examples (internal API)
- [ ] Write unit tests

#### `Common/TextInput.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Common/Dispatch.swift` ✅ (Renamed from Dipsatch.swift)
- [✅] Fix filename typo: rename to `Dispatch.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Common/SectionedViewDataSourceType.swift`
- [✅] Add doc comments (already documented)
- [✅] Add usage examples
- [ ] Write unit tests

#### `Common/ControlTarget.swift`
- [✅] Add doc comments
- [✅] Add usage examples (internal API)
- [ ] Write unit tests

#### `Common/CombineTarget.swift`
- [✅] Add doc comments
- [✅] Add usage examples (internal API)
- [ ] Write unit tests

### 3.3 Traits ✅ **COMPLETE** (2/2 files)
#### `Traits/ControlEvent.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [✅] Write unit tests

#### `Traits/ControlProperty.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [✅] Write unit tests

### 3.4 Foundation Extensions ✅ **COMPLETE** (2/2 files)
#### `Foundation/URLSession+Combine.swift`
- [✅] Add doc comments
- [✅] Add practical examples with API calls
- [ ] Write unit tests
- [ ] Test error handling

#### `Foundation/NSObject+Combine.swift`
- [✅] Add doc comments
- [✅] Add KVO examples
- [ ] Write unit tests

### 3.5 iOS UI Controls ✅ **COMPLETE** (15/15 files)
#### `iOS/UIControl+Rx.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `iOS/UIButton+Rx.swift`
- [✅] Add doc comments
- [✅] Add tap handling examples
- [ ] Write unit tests

#### `iOS/UITextField+Rx.swift`
- [✅] Add doc comments
- [✅] Add text binding examples
- [ ] Write unit tests

#### `iOS/UISwitch+Rx.swift`
- [✅] Add doc comments
- [✅] Add binding examples
- [ ] Write unit tests

#### `iOS/UISlider+Rx.swift`
- [✅] Add doc comments
- [✅] Add value binding examples
- [ ] Write unit tests

#### `iOS/UIStepper+Rx.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `iOS/UISegmentedControl+Rx.swift`
- [✅] Add doc comments
- [✅] Add selection examples
- [ ] Write unit tests

#### `iOS/UIDatePicker+Rx.swift`
- [✅] Add doc comments
- [✅] Add date binding examples
- [ ] Write unit tests

#### `iOS/UIRefreshControl+Rx.swift`
- [✅] Add doc comments
- [✅] Add pull-to-refresh examples
- [ ] Write unit tests

#### `iOS/UIStackView+Rx.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `iOS/UIView+Rx.swift`
- [✅] Add doc comments
- [✅] Add visibility/frame tracking examples
- [ ] Write unit tests

#### `iOS/UIActivityIndicatorView+Rx.swift`
- [✅] Add doc comments
- [✅] Add loading indicator examples
- [ ] Write unit tests

#### `iOS/UIApplication+Rx.swift`
- [✅] Add doc comments
- [✅] Add app state examples
- [ ] Write unit tests

#### `iOS/UIBarButtonItem+Rx.swift`
- [✅] Add doc comments
- [✅] Add tap handling examples
- [ ] Write unit tests

#### `iOS/UIGestureRecognizer+Rx.swift`
- [✅] Add doc comments
- [✅] Add gesture handling examples
- [ ] Write unit tests

### 3.6 Gesture Recognition ✅ **COMPLETE** (16/16 files)
#### `Gestures/GestureFactory.swift`
- [✅] Add doc comments
- [✅] Add factory pattern examples
- [ ] Write unit tests

#### `Gestures/View+CombineGesture.swift`
- [✅] Add doc comments
- [✅] Add gesture binding examples
- [ ] Write unit tests

#### `Gestures/GestureRecognizer+CombineGesture.swift`
- [✅] Add doc comments
- [✅] Add usage examples
- [ ] Write unit tests

#### `Gestures/SharedTypes.swift`
- [✅] Add doc comments
- [✅] Document shared gesture types
- [ ] Write unit tests

#### `Gestures/GenericCombineGestureRecognizerDelegate.swift`
- [✅] Add doc comments
- [✅] Add delegate pattern examples
- [ ] Write unit tests

#### `Gestures/iOS/UITapGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add tap gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/UIPanGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add pan gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/UIPinchGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add pinch gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/UIRotationGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add rotation gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/UISwipeGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add swipe gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/UILongPressGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/UIScreenEdgePanGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add edge pan examples
- [ ] Write unit tests

#### `Gestures/iOS/UIHoverGestureRecognizer+RxGesture.swift`
- [✅] Add doc comments
- [✅] Add hover gesture examples
- [ ] Write unit tests

#### `Gestures/iOS/TouchDownGestureRecognizer.swift`
- [✅] Add doc comments (internal gesture recognizer)
- [ ] Write unit tests

#### `Gestures/iOS/ForceTouchGestureRecognizer.swift`
- [✅] Add doc comments (internal gesture recognizer)
- [ ] Write unit tests

#### `Gestures/iOS/TransformGestureRecognizers.swift`
- [✅] Add doc comments (internal gesture recognizers)
- [ ] Write unit tests

---

## 4. Testing Infrastructure

### 4.1 Setup Test Target
- [✅] Create Tests directory
- [✅] Add test target to Package.swift (CombineCocoaTests)
- [✅] Set up test dependencies (TestUtilities shared module)
- [✅] Create test helpers and utilities (Expectation, TestSubscriber, TestSubscription)
- [ ] Set up CI for running tests

### 4.2 Test Organization
- [✅] Create CombineOperatorsTests folder (existing with 17 test files)
- [✅] Create CombineCocoaTests folder
- [✅] Create SharedTestUtilities for common test helpers (TestUtilities module)
- [ ] Add mock objects for UI testing (requires simulator)

---

## 5. Documentation

### 5.1 Project-Level Documentation
- [ ] Update README.md with comprehensive examples
- [ ] Add CONTRIBUTING.md
- [ ] Add CHANGELOG.md
- [ ] Add migration guide (if applicable)
- [ ] Add documentation for common patterns

### 5.2 Module Documentation
- [ ] Add README for CombineOperators module
- [ ] Add README for CombineCocoa module
- [ ] Add architecture decision records (if needed)

---

## 6. Code Quality

### 6.1 Code Review
- [ ] Fix filename typo: `Dipsatch.swift` → `Dispatch.swift`
- [ ] Review naming conventions across all files
- [ ] Check for code duplication
- [ ] Ensure consistent formatting
- [ ] Review access control modifiers

### 6.2 Performance
- [ ] Profile key operations
- [ ] Optimize hot paths if needed
- [ ] Add performance benchmarks

---

## 7. Final Tasks

- [ ] Run all tests and ensure they pass
- [ ] Generate documentation with DocC
- [ ] Update version number
- [ ] Tag release
- [ ] Update package dependencies

---

## Progress Summary

### Statistics
- Total Files: ~62
- CombineOperators Files: ~19
- CombineCocoa Files: ~43
- Test Files: 0 (to be created)

### Current Status
- [✅] Phase 1: Structure & Organization
- [✅] Phase 2: Documentation (CombineOperators) - **COMPLETE** (All files documented)
- [✅] Phase 3: Documentation (CombineCocoa) - **COMPLETE** (All files documented)
  - [✅] Common infrastructure (8/8 files)
  - [✅] Traits (2/2 files)
  - [✅] Foundation extensions (2/2 files)
  - [✅] iOS UI controls (15/15 files)
  - [✅] Gesture recognition (16/16 files)
- [ ] Phase 4: Test Coverage
- [ ] Phase 5: Final Review & Release

### Recent Completions (Latest Session)
- [✅] CombineCocoa common infrastructure - Reactive, ReactiveBinder, HasObserver, CombineTarget, ControlTarget, TextInput, Dispatch
- [✅] CombineCocoa traits - ControlEvent, ControlProperty with guarantees and examples
- [✅] Foundation extensions - URLSession (response/data/json), NSObject (KVO, deallocation)
- [✅] iOS UI controls - All 15 files including UIControl, UIButton, UITextField, UISwitch, UISlider, UIStepper, UISegmentedControl, UIDatePicker, UIRefreshControl, UIStackView, UIView, UIActivityIndicatorView, UIApplication, UIBarButtonItem, UIGestureRecognizer
- [✅] Gesture recognition - All 16 files including GestureFactory, View+CombineGesture, GestureRecognizer+CombineGesture, SharedTypes, GenericCombineGestureRecognizerDelegate, and all iOS gesture recognizers (Tap, Pan, Pinch, Rotation, Swipe, LongPress, ScreenEdgePan, Hover, TouchDown, ForceTouch, Transform)
- [✅] CombineOperators remaining - OnDeinit, Subscriber++, Cancellable++, CombineError, CombinePrecedence, NSNotification++, MergeBuilder
- [✅] CombineCocoa.swift - Error enum with examples, helper functions, casting utilities
- [✅] **Documentation: All files documented (100%)**
- [✅] **Test Infrastructure**: Created TestUtilities shared module, added CombineCocoaTests target
- [✅] **CombineCocoa Tests**: ControlEvent, ControlProperty, Reactive wrapper, CombineCocoaError

---

**Notes:**
- Focus on public API documentation first
- Keep examples concise and practical
- Each test should cover happy path, edge cases, and error scenarios
- Update this checklist as work progresses
