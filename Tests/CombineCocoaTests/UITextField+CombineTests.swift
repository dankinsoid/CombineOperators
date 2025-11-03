import Combine
@testable import CombineCocoa
import TestUtilities
import Testing

#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

@MainActor
@Suite("UITextField+Combine Tests")
struct UITextFieldCombineTests {

	// MARK: - Text Property - Reading

	@Test("Text property emits initial value")
	func textPropertyEmitsInitialValue() async {
		let textField = UITextField()
		textField.text = "initial"

		let expectation = Expectation<String?>(limit: 1)

		let cancellable = textField.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == "initial")

		cancellable.cancel()
	}

	@Test("Text property emits on text change")
	func textPropertyEmitsOnTextChange() async {
		let textField = UITextField()
		textField.text = ""

		let expectation = Expectation<String?>(limit: 2)

		let cancellable = textField.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		textField.text = "changed"
		textField.triggerActions(for: .editingChanged)

		let values = await expectation.values

		#expect(values == ["", "changed"])

		cancellable.cancel()
	}

	@Test("Text property with nil value")
	func textPropertyWithNilValue() async throws {
		let textField = UITextField()
		textField.text = nil

		let expectation = Expectation<String?>(limit: 1)

		let cancellable = textField.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values
        try #require(values.count == 1)

		// UITextField converts nil to empty string
		#expect(values[0] == "")

		cancellable.cancel()
	}

	// MARK: - Text Property - Writing

	@Test("Text property binding")
	func textPropertyBinding() async {
		let textField = UITextField()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(textField.cb.text)

		subject.send("bound text")

		#expect(textField.text == "bound text")
	}

	@Test("Text property binding with nil")
	func textPropertyBindingWithNil() async {
		let textField = UITextField()
		textField.text = "initial"
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(textField.cb.text)

		subject.send(nil)

		// UITextField converts nil to empty string
		#expect(textField.text == "")
	}

	@Test("Text property binding multiple updates")
	func textPropertyBindingMultipleUpdates() async {
		let textField = UITextField()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(textField.cb.text)

		await Task.yield()

		subject.send("first")
		subject.send("second")
		subject.send("third")

		await Task.yield()

		#expect(textField.text == "third")
	}

	// MARK: - Text Property - IME Preservation

	@Test("Text property does not overwrite identical text")
	func textPropertyDoesNotOverwriteIdenticalText() async {
		let textField = UITextField()
		textField.text = "same"
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(textField.cb.text)

		await Task.yield()

		// Sending the same text should not trigger a change
		subject.send("same")

		await Task.yield()

		#expect(textField.text == "same")
	}

	// MARK: - Bidirectional Binding

	@Test("Bidirectional text binding")
	func bidirectionalTextBinding() async {
		let textField = UITextField()
		textField.text = "initial"

		let expectation = Expectation<String?>(limit: 1)
		let subject = PassthroughSubject<String?, Never>()

		// Subscribe to read changes
		let readCancellable = textField.cb.text
			.sink { value in
				expectation.fulfill(value)
			}

		let values = await expectation.values

		#expect(values.first == "initial")

		// Bind publisher to write changes
		subject.subscribe(textField.cb.text)

		await Task.yield()

		subject.send("from publisher")

		await Task.yield()

		#expect(textField.text == "from publisher")

		readCancellable.cancel()
	}

	// MARK: - Memory Management

	@Test("TextField deallocates after cancellation")
	func textFieldDeallocatesAfterCancellation() async {
		var textField: UITextField? = UITextField()
		weak var weakTextField = textField

		let cancellable = textField!.cb.text
			.sink { _ in }

		await Task.yield()

		cancellable.cancel()
		textField = nil

		await Task.yield()

		#expect(weakTextField == nil)
	}

	// MARK: - Edge Cases

	@Test("Empty string binding")
	func emptyStringBinding() async {
		let textField = UITextField()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(textField.cb.text)

		await Task.yield()

		subject.send("")

		await Task.yield()

		#expect(textField.text == "")
	}

	@Test("Rapid text updates")
	func rapidTextUpdates() async {
		let textField = UITextField()
		let subject = PassthroughSubject<String?, Never>()

		subject.subscribe(textField.cb.text)

		await Task.yield()

		for i in 1...50 {
			subject.send("text\(i)")
		}

		await Task.yield()

		#expect(textField.text == "text50")
	}
}

#endif // canImport(UIKit)
