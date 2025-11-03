import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

@MainActor
@Suite("UIControl+Combine Tests")
struct UIControlCombineTests {

	// MARK: - Test Control

	final class TestControl: UIControl {
		var testValue: String = ""

		func simulateValueChanged() {
            triggerActions(for: .valueChanged)
		}

		func simulateTouchUpInside() {
            triggerActions(for: .touchUpInside)
		}

		func simulateTouchDown() {
            triggerActions(for: .touchDown)
		}

		func simulateEditingChanged() {
            triggerActions(for: .editingChanged)
		}
	}

	// MARK: - Control Event Tests

	@Test("Control event emits on action")
	func controlEventEmitsOnAction() async {
		let control = TestControl()
		let expectation = Expectation<Void>(limit: 1)

		let cancellable = control.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation.fulfill(())
			}

		await Task.yield()

		control.simulateTouchUpInside()

		_ = await expectation.values

		cancellable.cancel()
	}

	@Test("Control event multiple events")
	func controlEventMultipleEvents() async {
		let control = TestControl()
		let expectation = Expectation<Void>(limit: 3)

		let cancellable = control.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation.fulfill(())
			}

		await Task.yield()

		control.simulateTouchUpInside()
		control.simulateTouchUpInside()
		control.simulateTouchUpInside()

        let count = await expectation.values.count

		#expect(count == 3)

		cancellable.cancel()
	}

	@Test("Control event with value changed")
	func controlEventWithValueChanged() async {
		let control = TestControl()
		let expectation = Expectation<Void>(limit: 1)

		let cancellable = control.cb.controlEvent(.valueChanged)
			.sink { _ in
				expectation.fulfill(())
			}

		await Task.yield()

		control.simulateValueChanged()

		_ = await expectation.values

		cancellable.cancel()
	}

	@Test("Control event with multiple event types")
	func controlEventWithMultipleEventTypes() async {
		let control = TestControl()
		let expectation = Expectation<Void>(limit: 2)

		let cancellable = control.cb.controlEvent([.touchUpInside, .touchDown])
			.sink { _ in
				expectation.fulfill(())
			}

		await Task.yield()

		control.simulateTouchDown()
		control.simulateTouchUpInside()

        let count = await expectation.values.count

		#expect(count == 2)

		cancellable.cancel()
	}

	// MARK: - Read-Only Control Property Tests

	@Test("Read-only control property emits initial value")
	func readOnlyControlPropertyEmitsInitialValue() async {
		let control = TestControl()
		control.testValue = "initial"

		let expectation = Expectation<String>(limit: 1)

		let cancellable = control.cb.controlProperty(\.testValue, on: .valueChanged)
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == "initial")

		cancellable.cancel()
	}

	@Test("Read-only control property emits on control event")
	func readOnlyControlPropertyEmitsOnControlEvent() async {
		let control = TestControl()
		control.testValue = "initial"

		let expectation = Expectation<String>(limit: 2)

		let cancellable = control.cb.controlProperty({ $0.testValue }, on: .valueChanged)
			.sink { value in
				expectation.fulfill(value)
			}

		await Task.yield()

		control.testValue = "changed"
		control.simulateValueChanged()

		let values = await expectation.values

		#expect(values == ["initial", "changed"])

		cancellable.cancel()
	}

	// MARK: - Bidirectional Control Property Tests

	@Test("Bidirectional control property getter")
	func bidirectionalControlPropertyGetter() async {
		let control = TestControl()
		control.testValue = "initial"

		let expectation = Expectation<String>(limit: 1)

		let property = control.cb.controlProperty(
			editingEvents: .valueChanged,
			getter: { $0.testValue },
			setter: { $0.testValue = $1 }
		)

		let cancellable = property.sink { value in
			expectation.fulfill(value)
		}

		let values = await expectation.values

		#expect(values.first == "initial")

		cancellable.cancel()
	}

	@Test("Bidirectional control property setter")
	func bidirectionalControlPropertySetter() async {
		let control = TestControl()

		let property = control.cb.controlProperty(
			editingEvents: .valueChanged,
			getter: { $0.testValue },
			setter: { $0.testValue = $1 }
		)

		await Task.yield()

		Just("bound value")
			.setFailureType(to: Never.self)
			.subscribe(property)

		await Task.yield()

		#expect(control.testValue == "bound value")
	}

	@Test("Bidirectional control property emits on editing event")
	func bidirectionalControlPropertyEmitsOnEditingEvent() async {
		let control = TestControl()
		control.testValue = "initial"

		let expectation = Expectation<String>(limit: 2)

		let property = control.cb.controlProperty(
			editingEvents: .editingChanged,
			getter: { $0.testValue },
			setter: { $0.testValue = $1 }
		)

		let cancellable = property.sink { value in
			expectation.fulfill(value)
		}

		await Task.yield()

		control.testValue = "edited"
		control.simulateEditingChanged()

		let values = await expectation.values

		#expect(values == ["initial", "edited"])

		cancellable.cancel()
	}

	// MARK: - Real UIControl Tests

	@Test("UIButton touch up inside")
	func uiButtonTouchUpInside() async {
		let button = UIButton()
		let expectation = Expectation<Void>(limit: 1)

		let cancellable = button.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation.fulfill(())
			}

		button.triggerActions(for: .touchUpInside)

		_ = await expectation.values

		cancellable.cancel()
	}

	@Test("UISlider value property")
	func uiSliderValueProperty() async {
		let slider = UISlider()
		slider.value = 0.0

		let expectation = Expectation<Float>(limit: 2)

		let property = slider.cb.controlProperty(
			editingEvents: .valueChanged,
			getter: { $0.value },
			setter: { $0.value = $1 }
		)

		let cancellable = property.sink { value in
			expectation.fulfill(value)
		}

		slider.value = 0.5
		slider.triggerActions(for: .valueChanged)

		let values = await expectation.values

		#expect(values.count == 2)
		#expect(abs(values.last! - 0.5) < 0.001)

		cancellable.cancel()
	}

	@Test("UISwitch is on property")
	func uiSwitchIsOnProperty() async {
		let switchControl = UISwitch()
		switchControl.isOn = false

		let expectation = Expectation<Bool>(limit: 1)

		let property = switchControl.cb.controlProperty(
			editingEvents: .valueChanged,
			getter: { $0.isOn },
			setter: { $0.isOn = $1 }
		)

		let cancellable = property.sink { value in
			expectation.fulfill(value)
		}

		let values = await expectation.values

		#expect(values.first == false)

		cancellable.cancel()
	}

	// MARK: - Weak Reference Tests

	@Test("Weak reference to control")
	func weakReferenceToControl() async {
		var control: TestControl? = TestControl()
		weak var weakControl = control

		let expectation = Expectation<Void>(limit: 1)

		let cancellable = control!.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation.fulfill(())
			}

		await Task.yield()

		control!.simulateTouchUpInside()

		_ = await expectation.values

		control = nil

		await Task.yield()

		#expect(weakControl == nil)

		cancellable.cancel()
	}

	// MARK: - Multiple Subscribers

	@Test("Multiple subscribers to same event")
	func multipleSubscribersToSameEvent() async {
		let control = TestControl()
		let expectation1 = Expectation<Void>(limit: 1)
		let expectation2 = Expectation<Void>(limit: 1)

		let cancellable1 = control.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation1.fulfill(())
			}

		let cancellable2 = control.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation2.fulfill(())
			}

		await Task.yield()

		control.simulateTouchUpInside()

		_ = await expectation1.values
		_ = await expectation2.values

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Edge Cases

	@Test("Control event with no subscribers")
	func controlEventWithNoSubscribers() {
		let control = TestControl()

		// Sending actions without subscribers should not crash
		control.simulateTouchUpInside()
		control.simulateValueChanged()
	}

	@Test("Cancelling control event")
	func cancellingControlEvent() async {
		let control = TestControl()
		let expectation = Expectation<Void>(limit: 1)

		let cancellable = control.cb.controlEvent(.touchUpInside)
			.sink { _ in
				expectation.fulfill(())
			}

		await Task.yield()

		control.simulateTouchUpInside()

		_ = await expectation.values

		cancellable.cancel()

		// Event after cancellation should not be received
		control.simulateTouchUpInside()

		await Task.yield()
	}
}

#endif // canImport(UIKit)
