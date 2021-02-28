//
//  UITabBar+Rx.swift
//  RxCocoa
//
//  Created by Jesse Farless on 5/13/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

/**
 iOS only
 */
#if os(iOS)
@available(iOS 13.0, macOS 10.15, *)@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITabBar {

    /// Reactive wrapper for `delegate` message `tabBar(_:willBeginCustomizing:)`.
    public var willBeginCustomizing: ControlEvent<[UITabBarItem]> {
        
        let source = delegate.methodInvoked(#selector(UITabBarDelegate.tabBar(_:willBeginCustomizing:)))
            .tryMap { a in
                return try castOrThrow([UITabBarItem].self, a[1])
            }

        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `tabBar(_:didBeginCustomizing:)`.
    public var didBeginCustomizing: ControlEvent<[UITabBarItem]> {
        let source = delegate.methodInvoked(#selector(UITabBarDelegate.tabBar(_:didBeginCustomizing:)))
            .tryMap { a in
                return try castOrThrow([UITabBarItem].self, a[1])
            }

        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `tabBar(_:willEndCustomizing:changed:)`.
    public var willEndCustomizing: ControlEvent<([UITabBarItem], Bool)> {
        let source = delegate.methodInvoked(#selector(UITabBarDelegate.tabBar(_:willEndCustomizing:changed:)))
            .tryMap { (a: [Any]) -> (([UITabBarItem], Bool)) in
                let items = try castOrThrow([UITabBarItem].self, a[1])
                let changed = try castOrThrow(Bool.self, a[2])
                return (items, changed)
            }

        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `delegate` message `tabBar(_:didEndCustomizing:changed:)`.
    public var didEndCustomizing: ControlEvent<([UITabBarItem], Bool)> {
        let source = delegate.methodInvoked(#selector(UITabBarDelegate.tabBar(_:didEndCustomizing:changed:)))
            .tryMap { (a: [Any]) -> (([UITabBarItem], Bool)) in
                let items = try castOrThrow([UITabBarItem].self, a[1])
                let changed = try castOrThrow(Bool.self, a[2])
                return (items, changed)
            }

        return ControlEvent(events: source)
    }

}
#endif

/**
 iOS and tvOS
 */
    
@available(iOS 13.0, macOS 10.15, *)@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITabBar {
    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<UITabBar, UITabBarDelegate> {
        RxTabBarDelegateProxy.proxy(for: base)
    }

    /// Reactive wrapper for `delegate` message `tabBar(_:didSelect:)`.
    public var didSelectItem: ControlEvent<UITabBarItem> {
        let source = delegate.methodInvoked(#selector(UITabBarDelegate.tabBar(_:didSelect:)))
            .tryMap { a in
                return try castOrThrow(UITabBarItem.self, a[1])
            }

        return ControlEvent(events: source)
    }

}

#endif
