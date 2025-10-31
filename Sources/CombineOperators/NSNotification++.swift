import Foundation
import Combine

extension NSNotification.Name {

	/// Shorthand publisher for this notification on default center.
	///
	/// ```swift
	/// NSNotification.Name.UIKeyboardWillShow.cb
	///     .sink { notification in
	///         // handle keyboard
	///     }
	/// ```
	public var cb: NotificationCenter.Publisher {
		NotificationCenter.Publisher(center: .default, name: self)
	}
}
