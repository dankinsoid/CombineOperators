//
//  CombinePickerViewDelegateProxy.swift
//  CombineCocoa
//
//  Created by Segii Shulga on 5/12/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import Combine
import UIKit

@available(iOS 13.0, macOS 10.15, *)
extension UIPickerView: HasDelegate {
	public typealias Delegate = UIPickerViewDelegate
}

@available(iOS 13.0, macOS 10.15, *)
open class CombinePickerViewDelegateProxy
: DelegateProxy<UIPickerView, UIPickerViewDelegate>
	, DelegateProxyType
	, UIPickerViewDelegate {
	
	/// Typed parent object.
	public weak private(set) var pickerView: UIPickerView?
	
	/// - parameter pickerView: Parent object for delegate proxy.
	public init(pickerView: ParentObject) {
		self.pickerView = pickerView
		super.init(parentObject: pickerView, delegateProxy: CombinePickerViewDelegateProxy.self)
	}
	
	// Register known implementationss
	public static func registerKnownImplementations() {
		self.register { CombinePickerViewDelegateProxy(pickerView: $0) }
	}
}
#endif

