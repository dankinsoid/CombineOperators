//
//  CombinePickerViewDataSourceType.swift
//  CombineCocoa
//
//  Created by Sergey Shulga on 05/07/2017.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)
    
import UIKit
import Combine

/// Marks data source as `UIPickerView` reactive data source enabling it to be used with one of the `bindTo` methods.
@available(iOS 13.0, macOS 10.15, *)
public protocol CombinePickerViewDataSourceType {
    /// Type of elements that can be bound to picker view.
    associatedtype Element
    
    /// New observable sequence event observed.
    ///
    /// - parameter pickerView: Bound picker view.
    /// - parameter observedEvent: Event
    func pickerView(_ pickerView: UIPickerView, observed: Element)
}
    
#endif
