//
//  CombineSearchBarDelegateProxy.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 7/4/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension UISearchBar: HasDelegate {
    public typealias Delegate = UISearchBarDelegate
}

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineSearchBarDelegateProxy
    : DelegateProxy<UISearchBar, UISearchBarDelegate>
    , DelegateProxyType 
    , UISearchBarDelegate {

    /// Typed parent object.
    public weak private(set) var searchBar: UISearchBar?

    /// - parameter searchBar: Parent object for delegate proxy.
    public init(searchBar: ParentObject) {
        self.searchBar = searchBar
        super.init(parentObject: searchBar, delegateProxy: CombineSearchBarDelegateProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineSearchBarDelegateProxy(searchBar: $0) }
    }
}

#endif
