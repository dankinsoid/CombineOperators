//
//  CombineCollectionViewDataSourceType.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 6/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

/// Marks data source as `UICollectionView` reactive data source enabling it to be used with one of the `bindTo` methods.
@available(iOS 13.0, macOS 10.15, *)
public protocol CombineCollectionViewDataSourceType /*: UICollectionViewDataSource*/ {
    
    /// Type of elements that can be bound to collection view.
    associatedtype Element
    
    /// New observable sequence event observed.
    ///
    /// - parameter collectionView: Bound collection view.
    /// - parameter observedEvent: Event
	func collectionView(_ collectionView: UICollectionView, observed: Element)
}

#endif
