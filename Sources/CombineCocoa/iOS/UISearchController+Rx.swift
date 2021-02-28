//
//  UISearchController+Rx.swift
//  RxCocoa
//
//  Created by Segii Shulga on 3/17/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)
    
    import Combine
    import UIKit
    
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UISearchController {
        /// Reactive wrapper for `delegate`.
        /// For more information take a look at `DelegateProxyType` protocol documentation.
        public var delegate: DelegateProxy<UISearchController, UISearchControllerDelegate> {
            return RxSearchControllerDelegateProxy.proxy(for: base)
        }

        /// Reactive wrapper for `delegate` message.
        public var didDismiss: AnyPublisher<Void, Error> {
            return delegate
                .methodInvoked( #selector(UISearchControllerDelegate.didDismissSearchController(_:)))
                .map { _ in }
							.eraseToAnyPublisher()
        }

        /// Reactive wrapper for `delegate` message.
        public var didPresent: AnyPublisher<Void, Error> {
            return delegate
                .methodInvoked(#selector(UISearchControllerDelegate.didPresentSearchController(_:)))
                .map { _ in }
							.eraseToAnyPublisher()
        }

        /// Reactive wrapper for `delegate` message.
        public var present: AnyPublisher<Void, Error> {
            return delegate
                .methodInvoked( #selector(UISearchControllerDelegate.presentSearchController(_:)))
                .map { _ in }
							.eraseToAnyPublisher()
        }

        /// Reactive wrapper for `delegate` message.
        public var willDismiss: AnyPublisher<Void, Error> {
            return delegate
                .methodInvoked(#selector(UISearchControllerDelegate.willDismissSearchController(_:)))
                .map { _ in }
							.eraseToAnyPublisher()
        }
        
        /// Reactive wrapper for `delegate` message.
        public var willPresent: AnyPublisher<Void, Error> {
            return delegate
                .methodInvoked( #selector(UISearchControllerDelegate.willPresentSearchController(_:)))
                .map { _ in }
							.eraseToAnyPublisher()
        }
        
    }
    
#endif
