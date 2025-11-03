import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

@MainActor
@Suite("UIButton+Combine Tests")
struct UIButtonCombineTests {

	// MARK: - Tap Event Tests

	#if os(iOS)
	@Test("Tap emits on touch up inside")
	func tapEmitsOnTouchUpInside() async {
		let button = UIButton()
		let expectation = Expectation<Void>(limit: 1)

		let cancellable = button.cb.tap
			.sink { _ in
				expectation.fulfill(())
			}

		button.triggerActions(for: .touchUpInside)

		_ = await expectation.values

		cancellable.cancel()
	}

	@Test("Tap multiple times")
	func tapMultipleTimes() async {
		let button = UIButton()
		let expectation = Expectation<Void>(limit: 3)

		let cancellable = button.cb.tap
			.sink { _ in
				expectation.fulfill(())
			}

		button.triggerActions(for: .touchUpInside)
		button.triggerActions(for: .touchUpInside)
		button.triggerActions(for: .touchUpInside)

        let count = await expectation.values.count

		#expect(count == 3)

		cancellable.cancel()
	}

	@Test("Tap with multiple subscribers")
	func tapWithMultipleSubscribers() async {
		let button = UIButton()
		let expectation1 = Expectation<Void>(limit: 1)
		let expectation2 = Expectation<Void>(limit: 1)

		let cancellable1 = button.cb.tap
			.sink { _ in
				expectation1.fulfill(())
			}

		let cancellable2 = button.cb.tap
			.sink { _ in
				expectation2.fulfill(())
			}

		button.triggerActions(for: .touchUpInside)

		_ = await expectation1.values
		_ = await expectation2.values

		cancellable1.cancel()
		cancellable2.cancel()
	}
	#endif

	// MARK: - Title Binding Tests

	@Test("Title binding for normal state")
	func titleBindingForNormalState() async {
		let button = UIButton()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(button.cb.title())

		subject.send("Test Title")

		#expect(button.title(for: .normal) == "Test Title")
	}

	@Test("Title binding with nil")
	func titleBindingWithNil() async {
		let button = UIButton()
		button.setTitle("Initial", for: .normal)
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(button.cb.title())

		subject.send(nil)

		#expect(button.title(for: .normal) == nil)
	}

	@Test("Title binding multiple updates")
	func titleBindingMultipleUpdates() async {
		let button = UIButton()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(button.cb.title())

		subject.send("First")
		subject.send("Second")
		subject.send("Third")

		#expect(button.title(for: .normal) == "Third")
	}

	// MARK: - Image Binding Tests

	@Test("Image binding for normal state")
	func imageBindingForNormalState() async {
		let button = UIButton()
		let image = UIImage()
		let subject = PassthroughSubject<UIImage?, Never>()

		subject.subscribe(button.cb.image())

		subject.send(image)

		#expect(button.image(for: .normal) != nil)
	}

	@Test("Image binding with nil")
	func imageBindingWithNil() async {
		let button = UIButton()
		let image = UIImage()
		button.setImage(image, for: .normal)

		let subject = PassthroughSubject<UIImage?, Never>()

		subject.subscribe(button.cb.image())

		subject.send(nil)

		#expect(button.image(for: .normal) == nil)
	}

	// MARK: - Background Image Binding Tests

	@Test("Background image binding")
	func backgroundImageBinding() async {
		let button = UIButton()
		let image = UIImage()
		let subject = PassthroughSubject<UIImage?, Never>()

		subject.subscribe(button.cb.backgroundImage())

		subject.send(image)

		#expect(button.backgroundImage(for: .normal) != nil)
	}

	// MARK: - Attributed Title Binding Tests

	@Test("Attributed title binding")
	func attributedTitleBinding() async {
		let button = UIButton()
		let attributedString = NSAttributedString(string: "Attributed")
		let subject = PassthroughSubject<NSAttributedString?, Never>()

		subject.subscribe(button.cb.attributedTitle())

		subject.send(attributedString)

		#expect(button.attributedTitle(for: .normal)?.string == "Attributed")
	}

	@Test("Attributed title binding with nil")
	func attributedTitleBindingWithNil() async {
		let button = UIButton()
		let attributedString = NSAttributedString(string: "Initial")
		button.setAttributedTitle(attributedString, for: .normal)

		let subject = PassthroughSubject<NSAttributedString?, Never>()

		subject.subscribe(button.cb.attributedTitle())

		subject.send(nil)

		#expect(button.attributedTitle(for: .normal) == nil)
	}

	// MARK: - Memory Management

	@Test("Button deallocates after cancellation")
	func buttonDeallocatesAfterCancellation() async {
		var button: UIButton? = UIButton()
		weak var weakButton = button

		let cancellable = button!.cb.tap
			.sink { _ in }

		cancellable.cancel()
		button = nil

		#expect(weakButton == nil)
	}

	@Test("Binding to multiple properties")
	func bindingToMultipleProperties() async {
		let button = UIButton()
		let titleSubject = PassthroughSubject<String?, Never>()
		let imageSubject = PassthroughSubject<UIImage?, Never>()

		titleSubject.subscribe(button.cb.title())
		imageSubject.subscribe(button.cb.image())


		titleSubject.send("Multi")
		imageSubject.send(UIImage())

		#expect(button.title(for: .normal) == "Multi")
		#expect(button.image(for: .normal) != nil)
	}
}

#endif // canImport(UIKit)
