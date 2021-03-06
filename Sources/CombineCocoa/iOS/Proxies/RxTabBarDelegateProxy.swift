//
//  CombineTabBarDelegateProxy.swift
//  CombineCocoa
//
//  Created by Jesse Farless on 5/14/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension UITabBar: HasDelegate {
    public typealias Delegate = UITabBarDelegate
}

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineTabBarDelegateProxy
    : DelegateProxy<UITabBar, UITabBarDelegate>
    , DelegateProxyType 
    , UITabBarDelegate {

    /// Typed parent object.
    public weak private(set) var tabBar: UITabBar?

    /// - parameter tabBar: Parent object for delegate proxy.
    public init(tabBar: ParentObject) {
        self.tabBar = tabBar
        super.init(parentObject: tabBar, delegateProxy: CombineTabBarDelegateProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineTabBarDelegateProxy(tabBar: $0) }
    }

    /// For more information take a look at `DelegateProxyType`.
    open class func currentDelegate(for object: ParentObject) -> UITabBarDelegate? {
        object.delegate
    }

    /// For more information take a look at `DelegateProxyType`.
    open class func setCurrentDelegate(_ delegate: UITabBarDelegate?, to object: ParentObject) {
        object.delegate = delegate
    }
}

#endif
