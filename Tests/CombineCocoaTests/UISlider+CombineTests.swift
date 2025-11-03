import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit) && os(iOS)
import UIKit

@MainActor
@Suite("UISlider+Combine Tests")
struct UISliderCombineTests {

	// MARK: - value Property - Reading

	@Test("Value emits initial value")
	func valueEmitsInitialValue() async {
		let slider = UISlider()
		slider.value = 0.5

		let expectation = Expectation<Float>(limit: 1)

		let cancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(abs(values[0] - 0.5) < 0.001)

		cancellable.cancel()
	}

	@Test("Value emits on change")
	func valueEmitsOnChange() async {
		let slider = UISlider()
		slider.value = 0.0

		let expectation = Expectation<Float>(limit: 2)

		let cancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		await Task.yield()

		slider.value = 0.75
		slider.triggerActions(for: .valueChanged)

		let values = await expectation.values

		#expect(abs(values.first! - 0.0) < 0.001)
		#expect(abs(values.last! - 0.75) < 0.001)

		cancellable.cancel()
	}

	// MARK: - value Property - Writing

	@Test("Value binding")
	func valueBinding() async {
		let slider = UISlider()
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(0.8)

		await Task.yield()

		#expect(abs(slider.value - 0.8) < 0.001)
	}

	@Test("Value binding multiple updates")
	func valueBindingMultipleUpdates() async {
		let slider = UISlider()
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(0.2)
		subject.send(0.4)
		subject.send(0.6)
		subject.send(0.9)

		await Task.yield()

		#expect(abs(slider.value - 0.9) < 0.001)
	}

	@Test("Value binding with min max")
	func valueBindingWithMinMax() async {
		let slider = UISlider()
		slider.minimumValue = 0.0
		slider.maximumValue = 100.0
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(50.0)

		await Task.yield()

		#expect(abs(slider.value - 50.0) < 0.001)
	}

	// MARK: - Bidirectional Binding

	@Test("Bidirectional value binding")
	func bidirectionalValueBinding() async {
		let slider = UISlider()
		slider.value = 0.0

		let expectation = Expectation<Float>(limit: 1)
		let subject = PassthroughSubject<Float, Never>()

		// Subscribe to read changes
		let readCancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(abs(values.first! - 0.0) < 0.001)

		// Bind publisher to write changes
		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(0.5)

		await Task.yield()

		#expect(abs(slider.value - 0.5) < 0.001)

		readCancellable.cancel()
	}

	// MARK: - Control Events

	@Test("Value responds to value changed event")
	func valueRespondsToValueChangedEvent() async {
		let slider = UISlider()
		slider.value = 0.0

		let expectation = Expectation<Float>(limit: 2)

		let cancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		await Task.yield()

		slider.value = 1.0
		slider.triggerActions(for: .valueChanged)

		let values = await expectation.values

		#expect(abs(values.last! - 1.0) < 0.001)

		cancellable.cancel()
	}

	// MARK: - Range Tests

	@Test("Value at minimum")
	func valueAtMinimum() async {
		let slider = UISlider()
		slider.minimumValue = 0.0
		slider.maximumValue = 1.0
		slider.value = 0.0

		let expectation = Expectation<Float>(limit: 1)

		let cancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(abs(values.first! - 0.0) < 0.001)

		cancellable.cancel()
	}

	@Test("Value at maximum")
	func valueAtMaximum() async {
		let slider = UISlider()
		slider.minimumValue = 0.0
		slider.maximumValue = 1.0
		slider.value = 1.0

		let expectation = Expectation<Float>(limit: 1)

		let cancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(abs(values.first! - 1.0) < 0.001)

		cancellable.cancel()
	}

	@Test("Value with custom range")
	func valueWithCustomRange() async {
		let slider = UISlider()
		slider.minimumValue = -10.0
		slider.maximumValue = 10.0
		slider.value = 5.0

		let expectation = Expectation<Float>(limit: 1)

		let cancellable = slider.cb.value
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(abs(values.first! - 5.0) < 0.001)

		cancellable.cancel()
	}

	// MARK: - Multiple Subscribers

	@Test("Multiple subscribers to value")
	func multipleSubscribersToValue() async {
		let slider = UISlider()
		slider.value = 0.5

		let expectation1 = Expectation<Float>(limit: 1)
		let expectation2 = Expectation<Float>(limit: 1)

		let cancellable1 = slider.cb.value
			.sink { value in
				expectation1.fulfill(value)
			}

		let cancellable2 = slider.cb.value
			.sink { value in
				expectation2.fulfill(value)
			}

		let values1 = await expectation1.values
		let values2 = await expectation2.values

		#expect(abs(values1.first! - 0.5) < 0.001)
		#expect(abs(values2.first! - 0.5) < 0.001)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Memory Management

	@Test("Slider deallocates after cancellation")
	func sliderDeallocatesAfterCancellation() async {
		var slider: UISlider? = UISlider()
		weak var weakSlider = slider

		let cancellable = slider!.cb.value
			.sink { _ in }

		await Task.yield()

		cancellable.cancel()
		slider = nil

		await Task.yield()

		#expect(weakSlider == nil)
	}

	// MARK: - Edge Cases

	@Test("Rapid value changes")
	func rapidValueChanges() async {
		let slider = UISlider()
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		for i in 0..<50 {
			subject.send(Float(i) / 50.0)
		}

		await Task.yield()

		#expect(abs(slider.value - 49.0/50.0) < 0.01)
	}

	@Test("Precision values")
	func precisionValues() async {
		let slider = UISlider()
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		let preciseValue: Float = 0.123456789
		subject.send(preciseValue)

		await Task.yield()

		#expect(abs(slider.value - preciseValue) < 0.0001)
	}

	@Test("Negative values")
	func negativeValues() async {
		let slider = UISlider()
		slider.minimumValue = -100.0
		slider.maximumValue = 0.0
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(-50.0)

		await Task.yield()

		#expect(abs(slider.value - (-50.0)) < 0.001)
	}

	@Test("Very large values")
	func veryLargeValues() async {
		let slider = UISlider()
		slider.minimumValue = 0.0
		slider.maximumValue = 10000.0
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(5000.0)

		await Task.yield()

		#expect(abs(slider.value - 5000.0) < 0.1)
	}

	@Test("Zero value")
	func zeroValue() async {
		let slider = UISlider()
		let subject = PassthroughSubject<Float, Never>()

		subject.subscribe(slider.cb.value)

		await Task.yield()

		subject.send(0.0)

		await Task.yield()

		#expect(abs(slider.value) < 0.001)
	}
}

#endif // canImport(UIKit) && os(iOS)
