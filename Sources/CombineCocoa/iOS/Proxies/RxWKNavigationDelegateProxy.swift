//
//  CombineWKNavigationDelegateProxy.swift
//  CombineCocoa
//
//  Created by Giuseppe Lanza on 14/02/2020.
//  Copyright © 2020 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(macOS)

import Combine
import WebKit

@available(iOS 8.0, OSX 10.10, OSXApplicationExtension 10.10, *)
@available(iOS 13.0, macOS 10.15, *)
open class CombineWKNavigationDelegateProxy
    : DelegateProxy<WKWebView, WKNavigationDelegate>
    , DelegateProxyType
, WKNavigationDelegate {

    /// Typed parent object.
    public weak private(set) var webView: WKWebView?

    /// - parameter webView: Parent object for delegate proxy.
    public init(webView: ParentObject) {
        self.webView = webView
        super.init(parentObject: webView, delegateProxy: CombineWKNavigationDelegateProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineWKNavigationDelegateProxy(webView: $0) }
    }
    
    public static func currentDelegate(for object: WKWebView) -> WKNavigationDelegate? {
        object.navigationDelegate
    }
    
    public static func setCurrentDelegate(_ delegate: WKNavigationDelegate?, to object: WKWebView) {
        object.navigationDelegate = delegate
    }
}

#endif
