#if os(iOS) || os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UITextField {
	/// Bidirectional binding for text field's `text` property.
	///
	/// Setter preserves IME marked text selection by checking before assignment.
	///
	/// ```swift
	/// textField.cb.text
	///     .sink { print("Text: \($0 ?? "")") }
	///
	/// publisher.subscribe(textField.cb.text) // Bind to text field
	/// ```
	var text: ControlProperty<String?> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { textField in
				textField.text
			},
			setter: { textField, value in
				// This check is important because setting text value always clears control state
				// including marked text selection which is imporant for proper input
				// when IME input method is used.
				if textField.text != value {
					textField.text = value
				}
			}
		)
	}

	/// Bidirectional binding for text field's `attributedText` property.
	///
	/// Setter preserves IME marked text selection by checking before assignment.
	var attributedText: ControlProperty<NSAttributedString?> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { textField in
				textField.attributedText
			},
			setter: { textField, value in
				// This check is important because setting text value always clears control state
				// including marked text selection which is imporant for proper input
				// when IME input method is used.
				if textField.attributedText != value {
					textField.attributedText = value
				}
			}
		)
	}
}

#endif
