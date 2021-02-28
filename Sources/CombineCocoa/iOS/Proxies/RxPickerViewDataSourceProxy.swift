//
//  CombinePickerViewDataSourceProxy.swift
//  CombineCocoa
//
//  Created by Sergey Shulga on 05/07/2017.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension UIPickerView: HasDataSource {
    public typealias DataSource = UIPickerViewDataSource
}

@available(iOS 13.0, macOS 10.15, *)
private let pickerViewDataSourceNotSet = PickerViewDataSourceNotSet()

@available(iOS 13.0, macOS 10.15, *)
private final class PickerViewDataSourceNotSet: NSObject, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        0
    }
}

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
public class CombinePickerViewDataSourceProxy
    : DelegateProxy<UIPickerView, UIPickerViewDataSource>
    , DelegateProxyType
    , UIPickerViewDataSource {

    /// Typed parent object.
    public weak private(set) var pickerView: UIPickerView?

    /// - parameter pickerView: Parent object for delegate proxy.
    public init(pickerView: ParentObject) {
        self.pickerView = pickerView
        super.init(parentObject: pickerView, delegateProxy: CombinePickerViewDataSourceProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombinePickerViewDataSourceProxy(pickerView: $0) }
    }

    private weak var _requiredMethodsDataSource: UIPickerViewDataSource? = pickerViewDataSourceNotSet

    // MARK: UIPickerViewDataSource

    /// Required delegate method implementation.
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        (_requiredMethodsDataSource ?? pickerViewDataSourceNotSet).numberOfComponents(in: pickerView)
    }

    /// Required delegate method implementation.
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        (_requiredMethodsDataSource ?? pickerViewDataSourceNotSet).pickerView(pickerView, numberOfRowsInComponent: component)
    }
    
    /// For more information take a look at `DelegateProxyType`.
    public override func setForwardToDelegate(_ forwardToDelegate: UIPickerViewDataSource?, retainDelegate: Bool) {
        _requiredMethodsDataSource = forwardToDelegate ?? pickerViewDataSourceNotSet
        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
    }
}

#endif
