//
//  CombineCollectionViewDelegateProxy.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 6/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineCollectionViewDelegateProxy
    : CombineScrollViewDelegateProxy
    , UICollectionViewDelegate
    , UICollectionViewDelegateFlowLayout {

    /// Typed parent object.
    public weak private(set) var collectionView: UICollectionView?

    /// Initializes `CombineCollectionViewDelegateProxy`
    ///
    /// - parameter collectionView: Parent object for delegate proxy.
    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init(scrollView: collectionView)
    }
}

#endif
