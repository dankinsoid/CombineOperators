//
//  UITextField+Combine.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import UIKit

extension Reactive where Base: UITextField {
	/// Reactive wrapper for `text` property.
	public var text: ControlProperty<String?> {
		return base.cb.controlPropertyWithDefaultEvents(
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
	
	/// Bindable sink for `attributedText` property.
	public var attributedText: ControlProperty<NSAttributedString?> {
		return base.cb.controlPropertyWithDefaultEvents(
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
