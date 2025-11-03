import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit) && os(iOS)
import UIKit

@MainActor
@Suite("UISwitch+Combine Tests")
struct UISwitchCombineTests {

	// MARK: - isOn Property - Reading

	@Test("IsOn emits initial value")
	func isOnEmitsInitialValue() async {
		let switchControl = UISwitch()
		switchControl.isOn = true

		let expectation = Expectation<Bool>(limit: 1)

		let cancellable = switchControl.cb.isOn
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == true)

		cancellable.cancel()
	}

	@Test("IsOn emits on change")
	func isOnEmitsOnChange() async {
		let switchControl = UISwitch()
		switchControl.isOn = false

		let expectation = Expectation<Bool>(limit: 2)

		let cancellable = switchControl.cb.isOn
			.sink { value in
				expectation.fulfill(value)
			}

		await Task.yield()

		switchControl.isOn = true
		switchControl.triggerActions(for: .valueChanged)

		let values = await expectation.values

		#expect(values == [false, true])

		cancellable.cancel()
	}

	// MARK: - isOn Property - Writing

	@Test("IsOn binding")
	func isOnBinding() async {
		let switchControl = UISwitch()
		let subject = PassthroughSubject<Bool, Never>()

		subject.subscribe(switchControl.cb.isOn)

		await Task.yield()

		subject.send(true)

		await Task.yield()

		#expect(switchControl.isOn == true)
	}

	@Test("IsOn binding multiple updates")
	func isOnBindingMultipleUpdates() async {
		let switchControl = UISwitch()
		let subject = PassthroughSubject<Bool, Never>()

		subject.subscribe(switchControl.cb.isOn)

		await Task.yield()

		subject.send(true)
		subject.send(false)
		subject.send(true)
		subject.send(false)

		await Task.yield()

		#expect(switchControl.isOn == false)
	}

	// MARK: - value Property (Alias)

	@Test("Value property is alias for isOn")
	func valuePropertyIsAliasForIsOn() async {
		let switchControl = UISwitch()
		switchControl.isOn = true

		let expectation1 = Expectation<Bool>(limit: 1)
		let expectation2 = Expectation<Bool>(limit: 1)

		let cancellable1 = switchControl.cb.isOn
			.sink { value in
				expectation1.fulfill(value)
			}

		let cancellable2 = switchControl.cb.value
			.sink { value in
				expectation2.fulfill(value)
			}

		let values1 = await expectation1.values
		let values2 = await expectation2.values

		#expect(values1.first == true)
		#expect(values2.first == true)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Bidirectional Binding

	@Test("Bidirectional isOn binding")
	func bidirectionalIsOnBinding() async {
		let switchControl = UISwitch()
		switchControl.isOn = false

		let expectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Bool, Never>()

		// Subscribe to read changes
		let readCancellable = switchControl.cb.isOn
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == false)

		// Bind publisher to write changes
		subject.subscribe(switchControl.cb.isOn)

		await Task.yield()

		subject.send(true)

		await Task.yield()

		#expect(switchControl.isOn == true)

		readCancellable.cancel()
	}

	// MARK: - Control Events

	@Test("IsOn responds to value changed event")
	func isOnRespondsToValueChangedEvent() async {
		let switchControl = UISwitch()
		switchControl.isOn = false

		let expectation = Expectation<Bool>(limit: 2)

		let cancellable = switchControl.cb.isOn
			.sink { value in
				expectation.fulfill(value)
			}

		await Task.yield()

		switchControl.isOn = true
		switchControl.triggerActions(for: .valueChanged)

		let values = await expectation.values

		#expect(values.last == true)

		cancellable.cancel()
	}

	// MARK: - Multiple Subscribers

	@Test("Multiple subscribers to isOn")
	func multipleSubscribersToIsOn() async {
		let switchControl = UISwitch()
		switchControl.isOn = true

		let expectation1 = Expectation<Bool>(limit: 1)
		let expectation2 = Expectation<Bool>(limit: 1)

		let cancellable1 = switchControl.cb.isOn
			.sink { value in
				expectation1.fulfill(value)
			}

		let cancellable2 = switchControl.cb.isOn
			.sink { value in
				expectation2.fulfill(value)
			}

		let values1 = await expectation1.values
		let values2 = await expectation2.values

		#expect(values1.first == true)
		#expect(values2.first == true)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Memory Management

	@Test("Switch deallocates after cancellation")
	func switchDeallocatesAfterCancellation() async {
		var switchControl: UISwitch? = UISwitch()
		weak var weakSwitch = switchControl

		let cancellable = switchControl!.cb.isOn
			.sink { _ in }

		await Task.yield()

		cancellable.cancel()
		switchControl = nil

		await Task.yield()

		#expect(weakSwitch == nil)
	}

	// MARK: - Edge Cases

	@Test("Rapid toggling")
	func rapidToggling() async {
		let switchControl = UISwitch()
		let subject = PassthroughSubject<Bool, Never>()

		subject.subscribe(switchControl.cb.isOn)

		await Task.yield()

		for i in 0..<20 {
			subject.send(i % 2 == 0)
		}

		await Task.yield()

		#expect(switchControl.isOn == false)
	}

	@Test("Setting same value multiple times")
	func settingSameValueMultipleTimes() async {
		let switchControl = UISwitch()
		let subject = PassthroughSubject<Bool, Never>()

		subject.subscribe(switchControl.cb.isOn)

		await Task.yield()

		// Send same value multiple times
		for _ in 0..<5 {
			subject.send(true)
		}

		await Task.yield()

		#expect(switchControl.isOn == true)
	}
}

#endif // canImport(UIKit) && os(iOS)
