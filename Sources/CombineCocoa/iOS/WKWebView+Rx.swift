//
//  WKWebView+Rx.swift
//  RxCocoa
//
//  Created by Giuseppe Lanza on 14/02/2020.
//  Copyright © 2020 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(macOS)

import Combine
import WebKit

@available(iOS 8.0, OSX 10.10, OSXApplicationExtension 10.10, *)@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: WKWebView {
    
    /// Reactive wrapper for `navigationDelegate`.
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var navigationDelegate: DelegateProxy<WKWebView, WKNavigationDelegate> {
        RxWKNavigationDelegateProxy.proxy(for: base)
    }
    
    /// Reactive wrapper for `navigationDelegate` message.
    public var didCommit: AnyPublisher<WKNavigation, Error> {
        navigationDelegate
            .methodInvoked(#selector(WKNavigationDelegate.webView(_:didCommit:)))
            .tryMap { a in try castOrThrow(WKNavigation.self, a[1]) }
					.eraseToAnyPublisher()
    }
    
    /// Reactive wrapper for `navigationDelegate` message.
    public var didStartLoad: AnyPublisher<WKNavigation, Error> {
        navigationDelegate
            .methodInvoked(#selector(WKNavigationDelegate.webView(_:didStartProvisionalNavigation:)))
            .tryMap { a in try castOrThrow(WKNavigation.self, a[1]) }
					.eraseToAnyPublisher()
    }

    /// Reactive wrapper for `navigationDelegate` message.
    public var didFinishLoad: AnyPublisher<WKNavigation, Error> {
        navigationDelegate
            .methodInvoked(#selector(WKNavigationDelegate.webView(_:didFinish:)))
            .tryMap { a in try castOrThrow(WKNavigation.self, a[1]) }
					.eraseToAnyPublisher()
    }

    /// Reactive wrapper for `navigationDelegate` message.
    public var didFailLoad: AnyPublisher<(WKNavigation, Error), Error> {
        navigationDelegate
            .methodInvoked(#selector(WKNavigationDelegate.webView(_:didFail:withError:)))
            .tryMap { a in
                (
                    try castOrThrow(WKNavigation.self, a[1]),
                    try castOrThrow(Error.self, a[2])
                )
            }
					.eraseToAnyPublisher()
    }
}

#endif
