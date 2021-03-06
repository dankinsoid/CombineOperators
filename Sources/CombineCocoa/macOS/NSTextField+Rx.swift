//
//  NSTextField+Combine.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 5/17/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(macOS)

import Cocoa
import Combine

/// Delegate proxy for `NSTextField`.
///
/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineTextFieldDelegateProxy
    : DelegateProxy<NSTextField, NSTextFieldDelegate>
    , DelegateProxyType 
    , NSTextFieldDelegate {

    /// Typed parent object.
    public weak private(set) var textField: NSTextField?

    /// Initializes `CombineTextFieldDelegateProxy`
    ///
    /// - parameter textField: Parent object for delegate proxy.
    init(textField: NSTextField) {
        self.textField = textField
        super.init(parentObject: textField, delegateProxy: CombineTextFieldDelegateProxy.self)
    }

    public static func registerKnownImplementations() {
        self.register { CombineTextFieldDelegateProxy(textField: $0) }
    }

    fileprivate let textSubject = PassthroughSubject<String?, Error>()

    // MARK: Delegate methods
    open func controlTextDidChange(_ notification: Notification) {
        let textField: NSTextField = castOrFatalError(notification.object)
        let nextValue = textField.stringValue
        self.textSubject.send(nextValue)
        _forwardToDelegate?.controlTextDidChange?(notification)
    }
    
    // MARK: Delegate proxy methods

    /// For more information take a look at `DelegateProxyType`.
    open class func currentDelegate(for object: ParentObject) -> NSTextFieldDelegate? {
        object.delegate
    }

    /// For more information take a look at `DelegateProxyType`.
    open class func setCurrentDelegate(_ delegate: NSTextFieldDelegate?, to object: ParentObject) {
        object.delegate = delegate
    }
    
}
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: NSTextField {

    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<NSTextField, NSTextFieldDelegate> {
        CombineTextFieldDelegateProxy.proxy(for: self.base)
    }
    
    /// Reactive wrapper for `text` property.
    public var text: ControlProperty<String?> {
        let delegate = CombineTextFieldDelegateProxy.proxy(for: self.base)
        
        let source = Deferred { [weak textField = self.base] in
            delegate.textSubject.prepend(textField?.stringValue)
        }.prefix(untilOutputFrom: self.deallocated)

        let observer = Binder(self.base) { (control, value: String?) in
            control.stringValue = value ?? ""
        }

        return ControlProperty(values: source, valueSink: observer)
    }
    
}

#endif
