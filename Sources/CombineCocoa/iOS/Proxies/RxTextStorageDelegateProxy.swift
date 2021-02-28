//
//  RxTextStorageDelegateProxy.swift
//  RxCocoa
//
//  Created by Segii Shulga on 12/30/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

    import Combine
    import UIKit

@available(iOS 13.0, macOS 10.15, *)
extension NSTextStorage: HasDelegate {
        public typealias Delegate = NSTextStorageDelegate
    }

@available(iOS 13.0, macOS 10.15, *)
    open class RxTextStorageDelegateProxy
        : DelegateProxy<NSTextStorage, NSTextStorageDelegate>
        , DelegateProxyType 
        , NSTextStorageDelegate {

        /// Typed parent object.
        public weak private(set) var textStorage: NSTextStorage?

        /// - parameter textStorage: Parent object for delegate proxy.
        public init(textStorage: NSTextStorage) {
            self.textStorage = textStorage
            super.init(parentObject: textStorage, delegateProxy: RxTextStorageDelegateProxy.self)
        }

        // Register known implementations
        public static func registerKnownImplementations() {
            self.register { RxTextStorageDelegateProxy(textStorage: $0) }
        }
    }
#endif
