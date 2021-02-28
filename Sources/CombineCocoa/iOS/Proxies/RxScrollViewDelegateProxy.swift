//
//  CombineScrollViewDelegateProxy.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 6/19/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import UIKit
    
@available(iOS 13.0, macOS 10.15, *)
extension UIScrollView: HasDelegate {
    public typealias Delegate = UIScrollViewDelegate
}

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineScrollViewDelegateProxy
    : DelegateProxy<UIScrollView, UIScrollViewDelegate>
    , DelegateProxyType 
    , UIScrollViewDelegate {

    /// Typed parent object.
    public weak private(set) var scrollView: UIScrollView?

    /// - parameter scrollView: Parent object for delegate proxy.
    public init(scrollView: ParentObject) {
        self.scrollView = scrollView
        super.init(parentObject: scrollView, delegateProxy: CombineScrollViewDelegateProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineScrollViewDelegateProxy(scrollView: $0) }
        self.register { CombineTableViewDelegateProxy(tableView: $0) }
        self.register { CombineCollectionViewDelegateProxy(collectionView: $0) }
        self.register { CombineTextViewDelegateProxy(textView: $0) }
    }

    private var _contentOffsetBehaviorSubject: CurrentValueSubject<CGPoint, Never>?
    private var _contentOffsetPublishSubject: PassthroughSubject<(), Error>?

    /// Optimized version used for observing content offset changes.
    internal var contentOffsetBehaviorSubject: CurrentValueSubject<CGPoint, Never> {
        if let subject = _contentOffsetBehaviorSubject {
            return subject
        }

        let subject = CurrentValueSubject<CGPoint, Never>(self.scrollView?.contentOffset ?? CGPoint.zero)
        _contentOffsetBehaviorSubject = subject

        return subject
    }

    /// Optimized version used for observing content offset changes.
    internal var contentOffsetPublishSubject: PassthroughSubject<(), Error> {
        if let subject = _contentOffsetPublishSubject {
            return subject
        }

        let subject = PassthroughSubject<(), Error>()
        _contentOffsetPublishSubject = subject

        return subject
    }
    
    // MARK: delegate methods

    /// For more information take a look at `DelegateProxyType`.
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let subject = _contentOffsetBehaviorSubject {
            subject.send(scrollView.contentOffset)
        }
        if let subject = _contentOffsetPublishSubject {
            subject.send()
        }
        self._forwardToDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    deinit {
        if let subject = _contentOffsetBehaviorSubject {
					subject.send(completion: .finished)
        }

        if let subject = _contentOffsetPublishSubject {
            subject.send(completion: .finished)
        }
    }
}

#endif
