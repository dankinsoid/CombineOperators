//
//  File.swift
//  
//
//  Created by Данил Войдилов on 10.03.2021.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineTextFieldDelegateProxy: DelegateProxy<UITextField, UITextFieldDelegate>, DelegateProxyType, UITextFieldDelegate {
	
	/// Typed parent object.
	public weak private(set) var textField: UITextField?
	
	/// - parameter textview: Parent object for delegate proxy.
	public init(textField: UITextField) {
		self.textField = textField
		super.init(parentObject: textField, delegateProxy: CombineTextFieldDelegateProxy.self)
	}
	
	// MARK: delegate methods
	
	@objc open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		forwardToDelegate()?.textFieldShouldBeginEditing?(textField) ?? true
	}
	
	@objc open func textFieldDidBeginEditing(_ textField: UITextField) {
		forwardToDelegate()?.textFieldDidBeginEditing?(textField)
	}
	
	@objc open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
		forwardToDelegate()?.textFieldShouldEndEditing?(textField) ?? true
	}
	
	@objc open func textFieldDidEndEditing(_ textField: UITextField) {
		forwardToDelegate()?.textFieldDidEndEditing?(textField)
	}
	
	@objc open func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
		forwardToDelegate()?.textFieldDidEndEditing?(textField, reason: reason)
	}
	
	@objc open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		forwardToDelegate()?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
	}
	
	@objc open func textFieldDidChangeSelection(_ textField: UITextField) {
		(forwardToDelegate()?.textFieldDidChangeSelection)?(textField)
	}
	
	@objc open func textFieldShouldClear(_ textField: UITextField) -> Bool {
		(forwardToDelegate()?.textFieldShouldClear)?(textField) ?? true
	}

	@objc open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		forwardToDelegate()?.textFieldShouldReturn?(textField) ?? true
	}
	
	public static func registerKnownImplementations() {
		self.register { CombineTextFieldDelegateProxy(textField: $0) }
	}
	
	public static func currentDelegate(for object: UITextField) -> UITextFieldDelegate? {
		object.delegate
	}
	
	public static func setCurrentDelegate(_ delegate: UITextFieldDelegate?, to object: UITextField) {
		object.delegate = delegate
	}
	
}

#endif
