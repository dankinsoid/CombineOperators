import Combine

#if os(iOS) || os(tvOS)
    import UIKit

    /// Represents text input with reactive extensions.
@available(iOS 13.0, macOS 10.15, *)
    public struct TextInput<Base: UITextInput> {
        /// Base text input to extend.
        public let base: Base

        /// Reactive wrapper for `text` property.
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

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITextField {
        /// Reactive text input.
        public var textInput: TextInput<Base> {
            return TextInput(base: base, text: self.text)
        }
    }

#endif
