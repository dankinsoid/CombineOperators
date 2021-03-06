//
//  CombineNavigationControllerDelegateProxy.swift
//  CombineCocoa
//
//  Created by Diogo on 13/04/17.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

    import UIKit
    import Combine

@available(iOS 13.0, macOS 10.15, *)
extension UINavigationController: HasDelegate {
        public typealias Delegate = UINavigationControllerDelegate
    }

    /// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
    open class CombineNavigationControllerDelegateProxy
        : DelegateProxy<UINavigationController, UINavigationControllerDelegate>
        , DelegateProxyType 
        , UINavigationControllerDelegate {

        /// Typed parent object.
        public weak private(set) var navigationController: UINavigationController?

        /// - parameter navigationController: Parent object for delegate proxy.
        public init(navigationController: ParentObject) {
            self.navigationController = navigationController
            super.init(parentObject: navigationController, delegateProxy: CombineNavigationControllerDelegateProxy.self)
        }

        // Register known implementations
        public static func registerKnownImplementations() {
            self.register { CombineNavigationControllerDelegateProxy(navigationController: $0) }
        }
    }
#endif
