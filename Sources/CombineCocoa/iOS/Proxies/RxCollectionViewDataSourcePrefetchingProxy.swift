//
//  CombineCollectionViewDataSourcePrefetchingProxy.swift
//  CombineCocoa
//
//  Created by Rowan Livingstone on 2/15/18.
//  Copyright © 2018 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension UICollectionView: HasPrefetchDataSource {
    public typealias PrefetchDataSource = UICollectionViewDataSourcePrefetching
}

@available(iOS 13.0, macOS 10.15, *)
private let collectionViewPrefetchDataSourceNotSet = CollectionViewPrefetchDataSourceNotSet()

@available(iOS 13.0, macOS 10.15, *)
private final class CollectionViewPrefetchDataSourceNotSet
    : NSObject
    , UICollectionViewDataSourcePrefetching {

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {}

}

@available(iOS 13.0, macOS 10.15, *)
open class CombineCollectionViewDataSourcePrefetchingProxy
    : DelegateProxy<UICollectionView, UICollectionViewDataSourcePrefetching>
    , DelegateProxyType
    , UICollectionViewDataSourcePrefetching {

    /// Typed parent object.
    public weak private(set) var collectionView: UICollectionView?

    /// - parameter collectionView: Parent object for delegate proxy.
    public init(collectionView: ParentObject) {
        self.collectionView = collectionView
        super.init(parentObject: collectionView, delegateProxy: CombineCollectionViewDataSourcePrefetchingProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineCollectionViewDataSourcePrefetchingProxy(collectionView: $0) }
    }

    private var _prefetchItemsPublishSubject: PassthroughSubject<[IndexPath], Error>?

    /// Optimized version used for observing prefetch items callbacks.
    internal var prefetchItemsPublishSubject: PassthroughSubject<[IndexPath], Error> {
        if let subject = _prefetchItemsPublishSubject {
            return subject
        }

        let subject = PassthroughSubject<[IndexPath], Error>()
        _prefetchItemsPublishSubject = subject

        return subject
    }

    private weak var _requiredMethodsPrefetchDataSource: UICollectionViewDataSourcePrefetching? = collectionViewPrefetchDataSourceNotSet

    // MARK: delegate

    /// Required delegate method implementation.
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        if let subject = _prefetchItemsPublishSubject {
            subject.send(indexPaths)
        }

        (_requiredMethodsPrefetchDataSource ?? collectionViewPrefetchDataSourceNotSet).collectionView(collectionView, prefetchItemsAt: indexPaths)
    }

    /// For more information take a look at `DelegateProxyType`.
    open override func setForwardToDelegate(_ forwardToDelegate: UICollectionViewDataSourcePrefetching?, retainDelegate: Bool) {
        _requiredMethodsPrefetchDataSource = forwardToDelegate ?? collectionViewPrefetchDataSourceNotSet
        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
    }

    deinit {
        if let subject = _prefetchItemsPublishSubject {
            subject.send(completion: .finished)
        }
    }

}

#endif
