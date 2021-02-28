//
//  UITableView+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 4/2/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import UIKit

// Items
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITableView {

    /**
    Binds sequences of elements to table view rows.
    
    - parameter source: Observable sequence of items.
    - parameter cellFactory: Transform between sequence elements and view cells.
    - returns: Cancellable object that can be used to unbind.
     
     Example:
    
         let items = Observable.just([
             "First Item",
             "Second Item",
             "Third Item"
         ])

         items
         .bind(to: tableView.cb.items) { (tableView, row, element) in
             let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
             cell.textLabel?.text = "\(element) @ row \(row)"
             return cell
         }
         .disposed(by: disposeBag)

     */
    public func items<Sequence: Swift.Sequence, Source: Publisher>
        (_ source: Source)
        -> (_ cellFactory: @escaping (UITableView, Int, Sequence.Element) -> UITableViewCell)
        -> Cancellable
        where Source.Output == Sequence {
            return { cellFactory in
                let dataSource = RxTableViewReactiveArrayDataSourceSequenceWrapper<Sequence>(cellFactory: cellFactory)
                return self.items(dataSource: dataSource)(source)
            }
    }

    /**
    Binds sequences of elements to table view rows.
    
    - parameter cellIdentifier: Identifier used to dequeue cells.
    - parameter source: Observable sequence of items.
    - parameter configureCell: Transform between sequence elements and view cells.
    - parameter cellType: Type of table view cell.
    - returns: Cancellable object that can be used to unbind.
     
     Example:

         let items = Observable.just([
             "First Item",
             "Second Item",
             "Third Item"
         ])

         items
             .bind(to: tableView.cb.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { (row, element, cell) in
                cell.textLabel?.text = "\(element) @ row \(row)"
             }
             .disposed(by: disposeBag)
    */
    public func items<Sequence: Swift.Sequence, Cell: UITableViewCell, Source: Publisher>
        (cellIdentifier: String, cellType: Cell.Type = Cell.self)
        -> (_ source: Source)
        -> (_ configureCell: @escaping (Int, Sequence.Element, Cell) -> Void)
        -> Cancellable
        where Source.Output == Sequence {
        return { source in
            return { configureCell in
                let dataSource = RxTableViewReactiveArrayDataSourceSequenceWrapper<Sequence> { tv, i, item in
                    let indexPath = IndexPath(item: i, section: 0)
                    let cell = tv.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! Cell
                    configureCell(i, item, cell)
                    return cell
                }
                return self.items(dataSource: dataSource)(source)
            }
        }
    }


    /**
    Binds sequences of elements to table view rows using a custom reactive data used to perform the transformation.
    This method will retain the data source for as long as the subscription isn't disposed (result `Cancellable` 
    being disposed).
    In case `source` observable sequence terminates successfully, the data source will present latest element
    until the subscription isn't disposed.
    
    - parameter dataSource: Data source used to transform elements to view cells.
    - parameter source: Observable sequence of items.
    - returns: Cancellable object that can be used to unbind.
    */
    public func items<
            DataSource: RxTableViewDataSourceType & UITableViewDataSource,
            Source: Publisher>
        (dataSource: DataSource)
        -> (_ source: Source)
        -> Cancellable
        where DataSource.Element == Source.Output {
        return { source in
            // This is called for sideeffects only, and to make sure delegate proxy is in place when
            // data source is being bound.
            // This is needed because theoretically the data source subscription itself might
            // call `self.cb.delegate`. If that happens, it might cause weird side effects since
            // setting data source will set delegate, and UITableView might get into a weird state.
            // Therefore it's better to set delegate proxy first, just to be sure.
            _ = self.delegate
            // Strong reference is needed because data source is in use until result subscription is disposed
            return source.subscribeProxyDataSource(ofObject: self.base, dataSource: dataSource as UITableViewDataSource, retainDataSource: true) { [weak tableView = self.base] (_: RxTableViewDataSourceProxy, event) -> Void in
                guard let tableView = tableView else {
                    return
                }
                dataSource.tableView(tableView, observed: event)
						} completion: {_, _ in }
        }
    }

}
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITableView {
    /**
    Reactive wrapper for `dataSource`.
    
    For more information take a look at `DelegateProxyType` protocol documentation.
    */
    public var dataSource: DelegateProxy<UITableView, UITableViewDataSource> {
        RxTableViewDataSourceProxy.proxy(for: base)
    }
   
    /**
    Installs data source as forwarding delegate on `rx.dataSource`.
    Data source won't be retained.
    
    It enables using normal delegate mechanism with reactive delegate mechanism.
     
    - parameter dataSource: Data source object.
    - returns: Cancellable object that can be used to unbind the data source.
    */
    public func setDataSource(_ dataSource: UITableViewDataSource)
        -> Cancellable {
        RxTableViewDataSourceProxy.installForwardDelegate(dataSource, retainDelegate: false, onProxyForObject: self.base)
    }
    
    // events
    
    /**
    Reactive wrapper for `delegate` message `tableView:didSelectRowAtIndexPath:`.
    */
    public var itemSelected: ControlEvent<IndexPath> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didSelectRowAt:)))
            .tryMap { a in
                return try castOrThrow(IndexPath.self, a[1])
            }

        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:didDeselectRowAtIndexPath:`.
     */
    public var itemDeselected: ControlEvent<IndexPath> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didDeselectRowAt:)))
            .tryMap { a in
                return try castOrThrow(IndexPath.self, a[1])
            }

        return ControlEvent(events: source)
    }
    
    /**
     Reactive wrapper for `delegate` message `tableView:didHighlightRowAt:`.
     */
    public var itemHighlighted: ControlEvent<IndexPath> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didHighlightRowAt:)))
            .tryMap { a in
                return try castOrThrow(IndexPath.self, a[1])
            }

        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:didUnhighlightRowAt:`.
     */
    public var itemUnhighlighted: ControlEvent<IndexPath> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didUnhighlightRowAt:)))
            .tryMap { a in
                return try castOrThrow(IndexPath.self, a[1])
            }

        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:accessoryButtonTappedForRowWithIndexPath:`.
     */
    public var itemAccessoryButtonTapped: ControlEvent<IndexPath> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:accessoryButtonTappedForRowWith:)))
            .tryMap { a in
                return try castOrThrow(IndexPath.self, a[1])
            }
        
        return ControlEvent(events: source)
    }
    
    /**
    Reactive wrapper for `delegate` message `tableView:commitEditingStyle:forRowAtIndexPath:`.
    */
    public var itemInserted: ControlEvent<IndexPath> {
        let source = self.dataSource.methodInvoked(#selector(UITableViewDataSource.tableView(_:commit:forRowAt:)))
            .tryFilter { a in
                return UITableViewCell.EditingStyle(rawValue: (try castOrThrow(NSNumber.self, a[1])).intValue) == .insert
            }
            .tryMap { a in
                return (try castOrThrow(IndexPath.self, a[2]))
        }
        
        return ControlEvent(events: source)
    }
    
    /**
    Reactive wrapper for `delegate` message `tableView:commitEditingStyle:forRowAtIndexPath:`.
    */
    public var itemDeleted: ControlEvent<IndexPath> {
        let source = self.dataSource.methodInvoked(#selector(UITableViewDataSource.tableView(_:commit:forRowAt:)))
            .tryFilter { a in
                return UITableViewCell.EditingStyle(rawValue: (try castOrThrow(NSNumber.self, a[1])).intValue) == .delete
            }
            .tryMap { a in
                return try castOrThrow(IndexPath.self, a[2])
            }
        
        return ControlEvent(events: source)
    }
    
    /**
    Reactive wrapper for `delegate` message `tableView:moveRowAtIndexPath:toIndexPath:`.
    */
    public var itemMoved: ControlEvent<ItemMovedEvent> {
        let source = self.dataSource.methodInvoked(#selector(UITableViewDataSource.tableView(_:moveRowAt:to:)))
            .tryMap { a in
                return (try castOrThrow(IndexPath.self, a[1]), try castOrThrow(IndexPath.self, a[2])) as ItemMovedEvent
            }
        
        return ControlEvent(events: source)
    }

    /**
    Reactive wrapper for `delegate` message `tableView:willDisplayCell:forRowAtIndexPath:`.
    */
    public var willDisplayCell: ControlEvent<WillDisplayCellEvent> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:willDisplay:forRowAt:)))
            .tryMap { a in
                return (try castOrThrow(UITableViewCell.self, a[1]), try castOrThrow(IndexPath.self, a[2])) as WillDisplayCellEvent
            }

        return ControlEvent(events: source)
    }

    /**
    Reactive wrapper for `delegate` message `tableView:didEndDisplayingCell:forRowAtIndexPath:`.
    */
    public var didEndDisplayingCell: ControlEvent<DidEndDisplayingCellEvent> {
        let source = self.delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didEndDisplaying:forRowAt:)))
            .tryMap { a in
                return (try castOrThrow(UITableViewCell.self, a[1]), try castOrThrow(IndexPath.self, a[2])) as DidEndDisplayingCellEvent
            }

        return ControlEvent(events: source)
    }

    /**
    Reactive wrapper for `delegate` message `tableView:didSelectRowAtIndexPath:`.
    
    It can be only used when one of the `rx.itemsWith*` methods is used to bind observable sequence,
    or any other data source conforming to `SectionedViewDataSourceType` protocol.
    
     ```
        tableView.cb.modelSelected(MyModel.self)
            .map { ...
     ```
    */
    public func modelSelected<T>(_ modelType: T.Type) -> ControlEvent<T> {
        let source = self.itemSelected.tryCompactMap { [weak view = self.base as UITableView] indexPath -> T? in
            guard let view = view else {
                return nil
            }
            return try view.cb.model(at: indexPath)
        }
        
        return ControlEvent(events: source)
    }

    /**
     Reactive wrapper for `delegate` message `tableView:didDeselectRowAtIndexPath:`.

     It can be only used when one of the `rx.itemsWith*` methods is used to bind observable sequence,
     or any other data source conforming to `SectionedViewDataSourceType` protocol.

     ```
        tableView.cb.modelDeselected(MyModel.self)
            .map { ...
     ```
     */
    public func modelDeselected<T>(_ modelType: T.Type) -> ControlEvent<T> {
         let source = self.itemDeselected.tryCompactMap { [weak view = self.base as UITableView] indexPath -> T? in
             guard let view = view else {
                 return nil
             }

            return try view.cb.model(at: indexPath)
        }

        return ControlEvent(events: source)
    }
    
    /**
     Reactive wrapper for `delegate` message `tableView:commitEditingStyle:forRowAtIndexPath:`.
     
     It can be only used when one of the `rx.itemsWith*` methods is used to bind observable sequence,
     or any other data source conforming to `SectionedViewDataSourceType` protocol.
     
     ```
        tableView.cb.modelDeleted(MyModel.self)
            .map { ...
     ```
     */
    public func modelDeleted<T>(_ modelType: T.Type) -> ControlEvent<T> {
        let source = self.itemDeleted.tryCompactMap { [weak view = self.base as UITableView] indexPath -> T? in
            guard let view = view else {
                return nil
            }
            
            return try view.cb.model(at: indexPath)
        }
        
        return ControlEvent(events: source)
    }

    /**
     Synchronous helper method for retrieving a model at indexPath through a reactive data source.
     */
    public func model<T>(at indexPath: IndexPath) throws -> T {
        let dataSource: SectionedViewDataSourceType = castOrFatalError(self.dataSource.forwardToDelegate(), message: "This method only works in case one of the `rx.items*` methods was used.")
        
        let element = try dataSource.model(at: indexPath)

        return castOrFatalError(element)
    }
}
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITableView {

    /// Reactive wrapper for `prefetchDataSource`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var prefetchDataSource: DelegateProxy<UITableView, UITableViewDataSourcePrefetching> {
        RxTableViewDataSourcePrefetchingProxy.proxy(for: base)
    }

    /**
     Installs prefetch data source as forwarding delegate on `rx.prefetchDataSource`.
     Prefetch data source won't be retained.

     It enables using normal delegate mechanism with reactive delegate mechanism.

     - parameter prefetchDataSource: Prefetch data source object.
     - returns: Cancellable object that can be used to unbind the data source.
     */
    public func setPrefetchDataSource(_ prefetchDataSource: UITableViewDataSourcePrefetching)
        -> Cancellable {
            return RxTableViewDataSourcePrefetchingProxy.installForwardDelegate(prefetchDataSource, retainDelegate: false, onProxyForObject: self.base)
    }

    /// Reactive wrapper for `prefetchDataSource` message `tableView(_:prefetchRowsAt:)`.
    public var prefetchRows: ControlEvent<[IndexPath]> {
        let source = RxTableViewDataSourcePrefetchingProxy.proxy(for: base).prefetchRowsPublishSubject
        return ControlEvent(events: source)
    }

    /// Reactive wrapper for `prefetchDataSource` message `tableView(_:cancelPrefetchingForRowsAt:)`.
    public var cancelPrefetchingForRows: ControlEvent<[IndexPath]> {
        let source = prefetchDataSource.methodInvoked(#selector(UITableViewDataSourcePrefetching.tableView(_:cancelPrefetchingForRowsAt:)))
            .tryMap { a in
                return try castOrThrow(Array<IndexPath>.self, a[1])
        }

        return ControlEvent(events: source)
    }

}
#endif

#if os(tvOS)
    
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITableView {
        
        /**
         Reactive wrapper for `delegate` message `tableView:didUpdateFocusInContext:withAnimationCoordinator:`.
         */
        public var didUpdateFocusInContextWithAnimationCoordinator: ControlEvent<(context: UITableViewFocusUpdateContext, animationCoordinator: UIFocusAnimationCoordinator)> {
            
            let source = delegate.methodInvoked(#selector(UITableViewDelegate.tableView(_:didUpdateFocusIn:with:)))
                .map { a -> (context: UITableViewFocusUpdateContext, animationCoordinator: UIFocusAnimationCoordinator) in
                    let context = try castOrThrow(UITableViewFocusUpdateContext.self, a[1])
                    let animationCoordinator = try castOrThrow(UIFocusAnimationCoordinator.self, a[2])
                    return (context: context, animationCoordinator: animationCoordinator)
            }
            
            return ControlEvent(events: source)
        }
    }
#endif
