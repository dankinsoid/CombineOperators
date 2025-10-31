#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UIButton {

	/// Emits when button is tapped (`.touchUpInside`).
	///
	/// ```swift
	/// button.cb.tap.sink { print("Tapped") }
	/// ```
	var tap: ControlEvent<Void> {
		controlEvent(.touchUpInside)
	}
}

#endif

#if os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UIButton {

	/// Emits when tvOS button's primary action triggers.
	var primaryAction: ControlEvent<Void> {
		controlEvent(.primaryActionTriggered)
	}
}

#endif

#if os(iOS) || os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UIButton {

	/// Binds to button title for specified state.
	///
	/// ```swift
	/// publisher.subscribe(button.cb.title())
	/// ```
	func title(for controlState: UIControl.State = []) -> Binder<String?> {
		Binder(base) { button, title in
			button.setTitle(title, for: controlState)
		}
	}

	/// Binds to button image for specified state.
	func image(for controlState: UIControl.State = []) -> Binder<UIImage?> {
		Binder(base) { button, image in
			button.setImage(image, for: controlState)
		}
	}

	/// Binds to button background image for specified state.
	func backgroundImage(for controlState: UIControl.State = []) -> Binder<UIImage?> {
		Binder(base) { button, image in
			button.setBackgroundImage(image, for: controlState)
		}
	}
}
#endif

#if os(iOS) || os(tvOS)
import Combine
import UIKit

public extension Reactive where Base: UIButton {

	/// Binds to button attributed title for specified state.
	func attributedTitle(for controlState: UIControl.State = []) -> Binder<NSAttributedString?> {
		Binder(base) { button, attributedTitle in
			button.setAttributedTitle(attributedTitle, for: controlState)
		}
	}
}
#endif
