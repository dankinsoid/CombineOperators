//
//  NSTextStorage+Combine.swift
//  CombineCocoa
//
//  Created by Segii Shulga on 12/30/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)
    import Combine
    import UIKit
    
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: NSTextStorage {

        /// Reactive wrapper for `delegate`.
        ///
        /// For more information take a look at `DelegateProxyType` protocol documentation.
        public var delegate: DelegateProxy<NSTextStorage, NSTextStorageDelegate> {
            return CombineTextStorageDelegateProxy.proxy(for: base)
        }

        /// Reactive wrapper for `delegate` message.
        public var didProcessEditingRangeChangeInLength: AnyPublisher<(editedMask: NSTextStorage.EditActions, editedRange: NSRange, delta: Int), Error> {
            return delegate
                .methodInvoked(#selector(NSTextStorageDelegate.textStorage(_:didProcessEditing:range:changeInLength:)))
                .tryMap { a in
                    let editedMask = NSTextStorage.EditActions(rawValue: try castOrThrow(UInt.self, a[1]) )
                    let editedRange = try castOrThrow(NSValue.self, a[2]).rangeValue
                    let delta = try castOrThrow(Int.self, a[3])
                    
                    return (editedMask, editedRange, delta)
                }
							.eraseToAnyPublisher()
        }
    }
#endif
