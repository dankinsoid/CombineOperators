//
//  UINavigationController+Combine.swift
//  CombineCocoa
//
//  Created by Diogo on 13/04/17.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import UIKit
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UINavigationController {
    public typealias ShowEvent = (viewController: UIViewController, animated: Bool)

    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<UINavigationController, UINavigationControllerDelegate> {
        CombineNavigationControllerDelegateProxy.proxy(for: base)
    }

    /// Reactive wrapper for delegate method `navigationController(:willShow:animated:)`.
    public var willShow: ControlEvent<ShowEvent> {
        let source = delegate
            .methodInvoked(#selector(UINavigationControllerDelegate.navigationController(_:willShow:animated:)))
            .tryMap { arg -> ShowEvent in
                let viewController = try castOrThrow(UIViewController.self, arg[1])
                let animated = try castOrThrow(Bool.self, arg[2])
                return (viewController, animated)
        }
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for delegate method `navigationController(:didShow:animated:)`.
    public var didShow: ControlEvent<ShowEvent> {
        let source = delegate
            .methodInvoked(#selector(UINavigationControllerDelegate.navigationController(_:didShow:animated:)))
            .tryMap { arg -> ShowEvent in
                let viewController = try castOrThrow(UIViewController.self, arg[1])
                let animated = try castOrThrow(Bool.self, arg[2])
                return (viewController, animated)
        }
        return ControlEvent(events: source)
    }
}

#endif
