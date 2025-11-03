import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

@MainActor
@Suite("UITextView+Combine Tests")
struct UITextViewCombineTests {

	// MARK: - Text Property - Reading

	@Test("Text property emits initial value")
	func textPropertyEmitsInitialValue() async {
		let textView = UITextView()
		textView.text = "initial"

		let expectation = Expectation<String>(limit: 1)

		let cancellable = textView.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == "initial")

		cancellable.cancel()
	}

	@Test("Text property emits on text change via notification")
	func textPropertyEmitsOnTextChange() async {
		let textView = UITextView()
		textView.text = "initial"

		let expectation = Expectation<String>(limit: 2)

		let cancellable = textView.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		textView.text = "changed"
		NotificationCenter.default.post(
			name: UITextView.textDidChangeNotification,
			object: textView
		)

		let values = await expectation.values

		#expect(values == ["initial", "changed"])

		cancellable.cancel()
	}

	@Test("Text property with empty string")
	func textPropertyWithEmptyString() async {
		let textView = UITextView()
		textView.text = ""

		let expectation = Expectation<String>(limit: 1)

		let cancellable = textView.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == "")

		cancellable.cancel()
	}

	@Test("Text property with nil value becomes empty string")
	func textPropertyWithNilValue() async {
		let textView = UITextView()
		textView.text = nil

		let expectation = Expectation<String>(limit: 1)

		let cancellable = textView.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		// UITextView converts nil to empty string
		#expect(values.first == "")

		cancellable.cancel()
	}

	// MARK: - Text Property - Writing

	@Test("Text property binding")
	func textPropertyBinding() async {
		let textView = UITextView()
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		subject.send("bound text")

		#expect(textView.text == "bound text")
	}

	@Test("Text property binding with empty string")
	func textPropertyBindingWithEmptyString() async {
		let textView = UITextView()
		textView.text = "initial"
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		subject.send("")

		#expect(textView.text == "")
	}

	@Test("Text property binding multiple updates")
	func textPropertyBindingMultipleUpdates() async {
		let textView = UITextView()
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		subject.send("first")
		subject.send("second")
		subject.send("third")

		#expect(textView.text == "third")
	}

	@Test("Text property does not overwrite identical text")
	func textPropertyDoesNotOverwriteIdenticalText() async {
		let textView = UITextView()
		textView.text = "same"
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		// Sending the same text should not trigger a change
		subject.send("same")

		#expect(textView.text == "same")
	}

	// MARK: - Attributed Text Property - Writing

	@Test("Attributed text property binding")
	func attributedTextPropertyBinding() async {
		let textView = UITextView()
		let subject = PassthroughSubject<NSAttributedString, Never>()

		subject.subscribe(textView.cb.attributedText)

		let attributedString = NSAttributedString(string: "bound")
		subject.send(attributedString)

		#expect(textView.attributedText?.string == "bound")
	}

	@Test("Attributed text property binding with attributes")
	func attributedTextPropertyBindingWithAttributes() async {
		let textView = UITextView()
		let subject = PassthroughSubject<NSAttributedString, Never>()

		subject.subscribe(textView.cb.attributedText)

		let attributedString = NSAttributedString(
			string: "styled",
			attributes: [.font: UIFont.boldSystemFont(ofSize: 16)]
		)
		subject.send(attributedString)

		#expect(textView.attributedText?.string == "styled")
		#expect(textView.attributedText?.attributes(at: 0, effectiveRange: nil)[.font] != nil)
	}

	@Test("Attributed text property binding multiple updates")
	func attributedTextPropertyBindingMultipleUpdates() async {
		let textView = UITextView()
		let subject = PassthroughSubject<NSAttributedString, Never>()

		subject.subscribe(textView.cb.attributedText)

		subject.send(NSAttributedString(string: "first"))
		subject.send(NSAttributedString(string: "second"))
		subject.send(NSAttributedString(string: "third"))

		#expect(textView.attributedText?.string == "third")
	}

	@Test("Attributed text property does not overwrite identical text")
	func attributedTextPropertyDoesNotOverwriteIdenticalText() async {
		let textView = UITextView()
		let attributedString = NSAttributedString(string: "same")
		textView.attributedText = attributedString

		let subject = PassthroughSubject<NSAttributedString, Never>()

		subject.subscribe(textView.cb.attributedText)

		// Sending the same text should not trigger a change
		subject.send(attributedString)

		#expect(textView.attributedText?.string == "same")
	}

	// MARK: - Bidirectional Binding

	@Test("Bidirectional text binding")
	func bidirectionalTextBinding() async {
		let textView = UITextView()
		textView.text = "initial"

		let expectation = Expectation<String>(limit: 1)
		let subject = PassthroughSubject<String, Never>()

		// Subscribe to read changes
		let readCancellable = textView.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == "initial")

		// Bind publisher to write changes
		subject.subscribe(textView.cb.text)

		subject.send("from publisher")

		#expect(textView.text == "from publisher")

		readCancellable.cancel()
	}

	// MARK: - Memory Management

	@Test("TextView deallocates after cancellation")
	func textViewDeallocatesAfterCancellation() async {
		var textView: UITextView? = UITextView()
		weak var weakTextView = textView

		let cancellable = textView!.cb.text
			.sink { _ in }

		cancellable.cancel()
		textView = nil

		await Task.yield()

		#expect(weakTextView == nil)
	}

	// MARK: - Edge Cases

	@Test("Long text handling")
	func longTextHandling() async {
		let textView = UITextView()
		let longText = String(repeating: "a", count: 10000)
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		subject.send(longText)

		#expect(textView.text == longText)
	}

	@Test("Multiline text handling")
	func multilineTextHandling() async {
		let textView = UITextView()
		let multilineText = "line1\nline2\nline3"
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		subject.send(multilineText)

		#expect(textView.text == multilineText)
	}

	@Test("Special characters handling")
	func specialCharactersHandling() async {
		let textView = UITextView()
		let specialText = "emoji 😀 and symbols: @#$%^&*()"
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		subject.send(specialText)

		#expect(textView.text == specialText)
	}

	@Test("Rapid text updates")
	func rapidTextUpdates() async {
		let textView = UITextView()
		let subject = PassthroughSubject<String, Never>()

		subject.subscribe(textView.cb.text)

		for i in 1...50 {
			subject.send("text\(i)")
		}

		#expect(textView.text == "text50")
	}

	@Test("Text change notifications for multiple subscribers")
	func textChangeNotificationsForMultipleSubscribers() async {
		let textView = UITextView()
		textView.text = "initial"

		let expectation1 = Expectation<String>(limit: 2)
		let expectation2 = Expectation<String>(limit: 2)

		let cancellable1 = textView.cb.text
			.sink { value in
				expectation1.fulfill(value)
			}

		let cancellable2 = textView.cb.text
			.sink { value in
				expectation2.fulfill(value)
			}

		textView.text = "changed"
		NotificationCenter.default.post(
			name: UITextView.textDidChangeNotification,
			object: textView
		)

		let values1 = await expectation1.values
		let values2 = await expectation2.values

		#expect(values1 == ["initial", "changed"])
		#expect(values2 == ["initial", "changed"])

		cancellable1.cancel()
		cancellable2.cancel()
	}
}

#endif // canImport(UIKit)
