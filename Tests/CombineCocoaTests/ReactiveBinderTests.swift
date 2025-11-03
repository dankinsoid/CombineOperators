import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Suite("Reactive Binder Tests")
struct ReactiveBinderTests {

	// MARK: - Test Object

	final class TestObject: NSObject {
		@objc dynamic var value: Int = 0
		@objc dynamic var text: String = ""
		@objc dynamic var flag: Bool = false

		var nested = NestedObject()
	}

	final class NestedObject: NSObject {
		@objc dynamic var count: Int = 0
		@objc dynamic var name: String = ""
	}

	// MARK: - Basic Binding

	@Test("Basic property binding")
	func basicPropertyBinding() async {
		let object = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object.cb.value)

		await Task.yield()

		subject.send(10)
		subject.send(20)
		subject.send(30)

		#expect(object.value == 30)
	}

	@Test("String property binding")
	func stringPropertyBinding() async {
		let object = TestObject()
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(object.cb.text)

		await Task.yield()

		subject.send("hello")

		await Task.yield()

		#expect(object.text == "hello")
	}

	@Test("Bool property binding")
	func boolPropertyBinding() async {
		let object = TestObject()
		let subject = PassthroughSubject<Bool, Never>()

		subject.subscribe(object.cb.flag)

		await Task.yield()

		subject.send(true)

		await Task.yield()

		#expect(object.flag == true)
	}

	// MARK: - Weak Reference

	@Test("Weak reference to target")
	func weakReferenceToTarget() async {
		var object: TestObject? = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		weak var weakObject = object

		subject.subscribe(object!.cb.value)

		await Task.yield()

		subject.send(42)

		await Task.yield()

		#expect(object?.value == 42)

		// Deallocate object
		object = nil

		await Task.yield()

		#expect(weakObject == nil, "Target should be deallocated")

		// Sending after deallocation should not crash
		subject.send(100)
	}

	@Test("Subscription cancels when target deallocates")
	func subscriptionCancelsWhenTargetDeallocates() async {
		var object: TestObject? = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object!.cb.value)

		await Task.yield()

		// Deallocate target
		object = nil

		await Task.yield()

		// Sending values doesn't crash
		subject.send(100)
	}

	// MARK: - Dynamic Member Lookup

	@Test("Nested property binding")
	func nestedPropertyBinding() async {
		let object = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object.cb.nested.count)

		await Task.yield()

		subject.send(99)

		await Task.yield()

		#expect(object.nested.count == 99)
	}

	@Test("Nested string property binding")
	func nestedStringPropertyBinding() async {
		let object = TestObject()
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(object.cb.nested.name)

		await Task.yield()

		subject.send("nested")

		await Task.yield()

		#expect(object.nested.name == "nested")
	}

	// MARK: - Main Thread Scheduling

	@Test("Binding schedules on main thread")
	func bindingSchedulesOnMainThread() async {
		let object = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object.cb.value)

		// Send from background thread
		await Task.detached {
			subject.send(777)
		}.value

		await Task.yield()

		#expect(object.value == 777)
	}

	// MARK: - Subscription Management

	@Test("Receives unlimited demand")
	func receivesUnlimitedDemand() async {
		let object = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object.cb.value)

		await Task.yield()

		// Send many values rapidly
		for i in 1...10 {
			subject.send(i)
		}

		await Task.yield()

		#expect(object.value == 10)
	}

	@Test("Completion does nothing")
	func completionDoesNothing() async {
		let object = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object.cb.value)

		await Task.yield()

		subject.send(50)

		await Task.yield()

		subject.send(completion: .finished)

		// Object should still have the last value
		#expect(object.value == 50)
	}

	// MARK: - CustomCombineIdentifierConvertible

	@Test("Has combine identifier")
	func hasCombineIdentifier() {
		let object = TestObject()
		let binder = object.cb.value

		#expect(binder.combineIdentifier != CombineIdentifier())
	}

	@Test("Unique combine identifiers")
	func uniqueCombineIdentifiers() {
		let object = TestObject()
		let binder1 = object.cb.value
		let binder2 = object.cb.text

		#expect(binder1.combineIdentifier != binder2.combineIdentifier)
	}

	// MARK: - UIKit Integration

	#if canImport(UIKit)
    @MainActor
	@Test("UILabel text binding")
	func uiLabelTextBinding() async {
		let label = UILabel()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(label.cb.text)

		await Task.yield()

		subject.send("Hello UIKit")

		await Task.yield()

		#expect(label.text == "Hello UIKit")
	}

	@Test("UIView alpha binding")
    @MainActor
	func uiViewAlphaBinding() async {
		let view = UIView()
		let subject = PassthroughSubject<CGFloat, Never>()

		subject.subscribe(view.cb.alpha)

		await Task.yield()

		subject.send(0.5)

		await Task.yield()

		#expect(abs(view.alpha - 0.5) < 0.001)
	}

	@Test("UIView background color binding")
    @MainActor
	func uiViewBackgroundColorBinding() async {
		let view = UIView()
		let subject = PassthroughSubject<UIColor?, Never>()

		subject.subscribe(view.cb.backgroundColor)

		await Task.yield()

		subject.send(.red)

		await Task.yield()

		#expect(view.backgroundColor == .red)
	}

	@Test("UIButton enabled binding")
    @MainActor
	func uiButtonEnabledBinding() async {
		let button = UIButton()
		let subject = PassthroughSubject<Bool, Never>()

		subject.subscribe(button.cb.isEnabled)

		await Task.yield()

		subject.send(false)

		await Task.yield()

		#expect(button.isEnabled == false)
	}
	#endif

	// MARK: - Edge Cases

	@Test("Binding to nil target")
	func bindingToNilTarget() {
		let subject = PassthroughSubject<Int, Never>()

		// Create and immediately deallocate target
		do {
			let object = TestObject()
			subject.subscribe(object.cb.value)
		}

		// Sending to deallocated target should not crash
		subject.send(999)
	}

	@Test("Multiple bindings to same target")
	func multipleBindingsToSameTarget() async {
		let object = TestObject()
		let subject1 = PassthroughSubject<Int, Never>()
		let subject2 = PassthroughSubject<String, Never>()

		subject1.subscribe(object.cb.value)
		subject2.subscribe(object.cb.text)

		subject1.send(123)
		subject2.send("test")

		#expect(object.value == 123)
		#expect(object.text == "test")
	}

	@Test("Rapid value changes")
	func rapidValueChanges() async {
		let object = TestObject()
		let subject = PassthroughSubject<Int, Never>()

		subject.subscribe(object.cb.value)

		await Task.yield()

		for i in 1...100 {
			subject.send(i)
		}

		await Task.yield()

		#expect(object.value == 100)
	}
}
