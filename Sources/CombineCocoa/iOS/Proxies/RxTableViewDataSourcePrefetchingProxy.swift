//
//  CombineTableViewDataSourcePrefetchingProxy.swift
//  CombineCocoa
//
//  Created by Rowan Livingstone on 2/15/18.
//  Copyright © 2018 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension UITableView: HasPrefetchDataSource {
    public typealias PrefetchDataSource = UITableViewDataSourcePrefetching
}

@available(iOS 13.0, macOS 10.15, *)
private let tableViewPrefetchDataSourceNotSet = TableViewPrefetchDataSourceNotSet()

@available(iOS 13.0, macOS 10.15, *)
private final class TableViewPrefetchDataSourceNotSet
    : NSObject
    , UITableViewDataSourcePrefetching {

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {}

}

@available(iOS 13.0, macOS 10.15, *)
open class CombineTableViewDataSourcePrefetchingProxy
    : DelegateProxy<UITableView, UITableViewDataSourcePrefetching>
    , DelegateProxyType
    , UITableViewDataSourcePrefetching {

    /// Typed parent object.
    public weak private(set) var tableView: UITableView?

    /// - parameter tableView: Parent object for delegate proxy.
    public init(tableView: ParentObject) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: CombineTableViewDataSourcePrefetchingProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineTableViewDataSourcePrefetchingProxy(tableView: $0) }
    }

    private var _prefetchRowsPublishSubject: PassthroughSubject<[IndexPath], Error>?

    /// Optimized version used for observing prefetch rows callbacks.
    internal var prefetchRowsPublishSubject: PassthroughSubject<[IndexPath], Error> {
        if let subject = _prefetchRowsPublishSubject {
            return subject
        }

        let subject = PassthroughSubject<[IndexPath], Error>()
        _prefetchRowsPublishSubject = subject

        return subject
    }

    private weak var _requiredMethodsPrefetchDataSource: UITableViewDataSourcePrefetching? = tableViewPrefetchDataSourceNotSet

    // MARK: delegate

    /// Required delegate method implementation.
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        if let subject = _prefetchRowsPublishSubject {
            subject.send(indexPaths)
        }

        (_requiredMethodsPrefetchDataSource ?? tableViewPrefetchDataSourceNotSet).tableView(tableView, prefetchRowsAt: indexPaths)
    }

    /// For more information take a look at `DelegateProxyType`.
    open override func setForwardToDelegate(_ forwardToDelegate: UITableViewDataSourcePrefetching?, retainDelegate: Bool) {
        _requiredMethodsPrefetchDataSource = forwardToDelegate ?? tableViewPrefetchDataSourceNotSet
        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
    }

    deinit {
        if let subject = _prefetchRowsPublishSubject {
            subject.send(completion: .finished)
        }
    }

}

#endif

