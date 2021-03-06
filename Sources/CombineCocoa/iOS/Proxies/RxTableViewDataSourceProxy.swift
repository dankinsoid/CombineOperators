//
//  CombineTableViewDataSourceProxy.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 6/15/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine
    
@available(iOS 13.0, macOS 10.15, *)
extension UITableView: HasDataSource {
    public typealias DataSource = UITableViewDataSource
}

@available(iOS 13.0, macOS 10.15, *)
private let tableViewDataSourceNotSet = TableViewDataSourceNotSet()

@available(iOS 13.0, macOS 10.15, *)
private final class TableViewDataSourceNotSet
    : NSObject
    , UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        rxAbstractMethod(message: dataSourceNotSet)
    }
}

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineTableViewDataSourceProxy
    : DelegateProxy<UITableView, UITableViewDataSource>
    , DelegateProxyType 
    , UITableViewDataSource {

    /// Typed parent object.
    public weak private(set) var tableView: UITableView?

    /// - parameter tableView: Parent object for delegate proxy.
    public init(tableView: UITableView) {
        self.tableView = tableView
        super.init(parentObject: tableView, delegateProxy: CombineTableViewDataSourceProxy.self)
    }

    // Register known implementations
    public static func registerKnownImplementations() {
        self.register { CombineTableViewDataSourceProxy(tableView: $0) }
    }

    private weak var _requiredMethodsDataSource: UITableViewDataSource? = tableViewDataSourceNotSet

    // MARK: delegate

    /// Required delegate method implementation.
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (_requiredMethodsDataSource ?? tableViewDataSourceNotSet).tableView(tableView, numberOfRowsInSection: section)
    }

    /// Required delegate method implementation.
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        (_requiredMethodsDataSource ?? tableViewDataSourceNotSet).tableView(tableView, cellForRowAt: indexPath)
    }

    /// For more information take a look at `DelegateProxyType`.
    open override func setForwardToDelegate(_ forwardToDelegate: UITableViewDataSource?, retainDelegate: Bool) {
        _requiredMethodsDataSource = forwardToDelegate  ?? tableViewDataSourceNotSet
        super.setForwardToDelegate(forwardToDelegate, retainDelegate: retainDelegate)
    }

}

#endif
