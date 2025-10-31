import Combine

#if canImport(UIKit)
import UIKit

/// Wrapper providing reactive access to text input controls.
///
/// Combines base control with reactive text property for unified text handling.
public struct TextInput<Base: UITextInput> {
	/// Base text input to extend.
	public let base: Base

	/// Reactive text property (bidirectional binding).
	public let text: ControlProperty<String?>

	/// Initializes new text input.
	///
	/// - parameter base: Base object.
	/// - parameter text: Textual control property.
	public init(base: Base, text: ControlProperty<String?>) {
		self.base = base
		self.text = text
	}
}

public extension Reactive where Base: UITextField {
	/// Reactive text input wrapper.
	var textInput: TextInput<Base> {
		TextInput(base: base, text: text)
	}
}

#endif
