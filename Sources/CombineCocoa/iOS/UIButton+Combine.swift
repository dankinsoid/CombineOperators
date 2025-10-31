//
//  UIButton+Combine.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 3/28/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import Combine
import UIKit

extension Reactive where Base: UIButton {

	/// Emits when button is tapped (`.touchUpInside`).
	///
	/// ```swift
	/// button.cb.tap.sink { print("Tapped") }
	/// ```
	public var tap: ControlEvent<Void> {
        controlEvent(.touchUpInside)
    }
}

#endif

#if os(tvOS)

import Combine
import UIKit

extension Reactive where Base: UIButton {

	/// Emits when tvOS button's primary action triggers.
	public var primaryAction: ControlEvent<Void> {
        controlEvent(.primaryActionTriggered)
    }

}

#endif

#if os(iOS) || os(tvOS)

import Combine
import UIKit

extension Reactive where Base: UIButton {

	/// Binds to button title for specified state.
	///
	/// ```swift
	/// publisher.subscribe(button.cb.title())
	/// ```
	public func title(for controlState: UIControl.State = []) -> Binder<String?> {
        Binder(self.base) { button, title in
            button.setTitle(title, for: controlState)
        }
    }

	/// Binds to button image for specified state.
	public func image(for controlState: UIControl.State = []) -> Binder<UIImage?> {
        Binder(self.base) { button, image in
            button.setImage(image, for: controlState)
        }
    }

	/// Binds to button background image for specified state.
	public func backgroundImage(for controlState: UIControl.State = []) -> Binder<UIImage?> {
        Binder(self.base) { button, image in
            button.setBackgroundImage(image, for: controlState)
        }
    }

}
#endif

#if os(iOS) || os(tvOS)
    import Combine
    import UIKit
    
extension Reactive where Base: UIButton {

	/// Binds to button attributed title for specified state.
	public func attributedTitle(for controlState: UIControl.State = []) -> Binder<NSAttributedString?> {
		return Binder(self.base) { button, attributedTitle -> Void in
			button.setAttributedTitle(attributedTitle, for: controlState)
		}
	}
}
#endif
