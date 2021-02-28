//
//  CombineTableViewDataSourceType.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 6/26/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

/// Marks data source as `UITableView` reactive data source enabling it to be used with one of the `bindTo` methods.
@available(iOS 13.0, macOS 10.15, *)
public protocol CombineTableViewDataSourceType /*: UITableViewDataSource*/ {
    
    /// Type of elements that can be bound to table view.
    associatedtype Element
    
    /// New observable sequence event observed.
    ///
    /// - parameter tableView: Bound table view.
    /// - parameter observedEvent: Event
    func tableView(_ tableView: UITableView, observed: Element)
}

#endif
