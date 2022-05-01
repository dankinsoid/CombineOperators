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

@available(iOS 13.0, macOS 10.15, *)
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
	
	///
	////// Reactive wrapper for `delegate`.
	///
	/// For more information take a look at `DelegateProxyType` protocol documentation.
	public var delegate: CombineTextFieldDelegateProxy {
		return CombineTextFieldDelegateProxy.proxy(for: base)
	}
	
	private func invoked(_ selector: Selector) -> AnyPublisher<[Any], Never> {
		base.publisher(for: \.delegate).or(delegate).map {
			Reactive<UITextFieldDelegate>($0).methodInvoked(selector).skipFailure()
		}
		.switchToLatest()
		.any()
	}
	
	public var mayBeginEditing: ControlEvent<Void> {
		ControlEvent<()>(
			events: invoked(#selector(UITextFieldDelegate.textFieldShouldBeginEditing(_:))).map { _ in () }
		)
	}
	
	public var didBeginEditing: ControlEvent<Void> {
		ControlEvent<()>(
			events: invoked(#selector(UITextFieldDelegate.textFieldDidBeginEditing(_:))).map { _ in () }
		)
	}
	
	public var mayEndEditing: ControlEvent<Void> {
		ControlEvent<()>(
			events: invoked(#selector(UITextFieldDelegate.textFieldShouldEndEditing(_:))).map { _ in () }
		)
	}
	
	//	public var didEndEditing: ControlEvent<Void> {
	//		ControlEvent<()>(
	//			events: invoked(#selector(UITextFieldDelegate.textFieldDidEndEditing(_:))).map { _ in () }
	//		)
	//	}
	
	public var reasonEndEditing: ControlEvent<UITextField.DidEndEditingReason> {
		ControlEvent<UITextField.DidEndEditingReason>(
			events: invoked(#selector(UITextFieldDelegate.textFieldDidEndEditing(_:reason:)))
				.compactMap { args in
					(args.last as? Int).flatMap { UITextField.DidEndEditingReason(rawValue: $0) }
				}
		)
	}
	
	public var mayChange: ControlEvent<(NSRange, String)> {
		ControlEvent(
			events: invoked(#selector(UITextFieldDelegate.textField(_:shouldChangeCharactersIn:replacementString:)))
				.compactMap { args -> (NSRange, String)? in
					guard args.count > 1 else { return nil }
					return (args[1] as? NSRange).flatMap { range in
						(args.last as? String).map { (range, $0) }
					}
				}
		)
	}
	
	public var didChangeSelection: ControlEvent<Void> {
		ControlEvent<Void>(
			events: invoked(#selector(UITextFieldDelegate.textFieldDidChangeSelection(_:))).map { _ in () }
		)
	}
	
	public var mayClear: ControlEvent<Void> {
		ControlEvent<Void>(
			events: invoked(#selector(UITextFieldDelegate.textFieldShouldClear(_:))).map { _ in () }
		)
	}
	
	public var mayReturn: ControlEvent<Void> {
		ControlEvent<Void>(
			events: invoked(#selector(UITextFieldDelegate.textFieldShouldReturn(_:))).map { _ in () }
		)
	}
}

#endif
