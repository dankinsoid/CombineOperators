//
//  UIPickerView+Combine.swift
//  CombineCocoa
//
//  Created by Segii Shulga on 5/12/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)
    
    import Combine
    import UIKit

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIPickerView {

        /// Reactive wrapper for `delegate`.
        /// For more information take a look at `DelegateProxyType` protocol documentation.
        public var delegate: DelegateProxy<UIPickerView, UIPickerViewDelegate> {
            return CombinePickerViewDelegateProxy.proxy(for: base)
        }
        
        /// Installs delegate as forwarding delegate on `delegate`.
        /// Delegate won't be retained.
        ///
        /// It enables using normal delegate mechanism with reactive delegate mechanism.
        ///
        /// - parameter delegate: Delegate object.
        /// - returns: Cancellable object that can be used to unbind the delegate.
        public func setDelegate(_ delegate: UIPickerViewDelegate) -> Cancellable {
						CombinePickerViewDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: self.base)
        }
        
        /**
         Reactive wrapper for `dataSource`.
         
         For more information take a look at `DelegateProxyType` protocol documentation.
         */
        public var dataSource: DelegateProxy<UIPickerView, UIPickerViewDataSource> {
            return CombinePickerViewDataSourceProxy.proxy(for: base)
        }
        
        /**
         Reactive wrapper for `delegate` message `pickerView:didSelectRow:inComponent:`.
         */
        public var itemSelected: ControlEvent<(row: Int, component: Int)> {
            let source = delegate
                .methodInvoked(#selector(UIPickerViewDelegate.pickerView(_:didSelectRow:inComponent:)))
                .tryMap {
									(row: try castOrThrow(Int.self, $0[1]), component: try castOrThrow(Int.self, $0[2]))
                }
            return ControlEvent(events: source)
        }
        
        /**
         Reactive wrapper for `delegate` message `pickerView:didSelectRow:inComponent:`.
         
         It can be only used when one of the `rx.itemTitles, rx.itemAttributedTitles, items(_ source: O)` methods is used to bind observable sequence,
         or any other data source conforming to a `ViewDataSourceType` protocol.
         
         ```
         pickerView.cb.modelSelected(MyModel.self)
         .map { ...
         ```
         - parameter modelType: Type of a Model which bound to the dataSource
         */
        public func modelSelected<T>(_ modelType: T.Type) -> ControlEvent<[T]> {
            let source = itemSelected.tryCompactMap { [weak view = self.base as UIPickerView] _, component -> [T]? in
                guard let view = view else {
                    return nil
                }

                let model: [T] = try (0 ..< view.numberOfComponents).map { component in
                    let row = view.selectedRow(inComponent: component)
                    return try view.cb.model(at: IndexPath(row: row, section: component))
                }

                return model
            }
            
            return ControlEvent(events: source)
        }
        
        /**
         Binds sequences of elements to picker view rows.
         
         - parameter source: Publisher sequence of items.
         - parameter titleForRow: Transform between sequence elements and row titles.
         - returns: Cancellable object that can be used to unbind.
         
         Example:
         
            let items = Publisher.just([
                    "First Item",
                    "Second Item",
                    "Third Item"
                ])
         
            items
                .bind(to: pickerView.cb.itemTitles) { (row, element) in
                    return element.title
                }
                .disposed(by: disposeBag)
         
         */
        
        public func itemTitles<Sequence: Swift.Sequence, Source: Publisher>
            (_ source: Source)
            -> (_ titleForRow: @escaping (Int, Sequence.Element) -> String?)
            -> Cancellable where Source.Output == Sequence {
                return { titleForRow in
                    let adapter = CombineStringPickerViewAdapter<Sequence>(titleForRow: titleForRow)
                    return self.items(adapter: adapter)(source)
                }
        }
        
        /**
         Binds sequences of elements to picker view rows.
         
         - parameter source: Publisher sequence of items.
         - parameter attributedTitleForRow: Transform between sequence elements and row attributed titles.
         - returns: Cancellable object that can be used to unbind.
         
         Example:
         
         let items = Publisher.just([
                "First Item",
                "Second Item",
                "Third Item"
            ])
         
         items
            .bind(to: pickerView.cb.itemAttributedTitles) { (row, element) in
                return NSAttributedString(string: element.title)
            }
            .disposed(by: disposeBag)
        
         */

        public func itemAttributedTitles<Sequence: Swift.Sequence, Source: Publisher>
            (_ source: Source)
            -> (_ attributedTitleForRow: @escaping (Int, Sequence.Element) -> NSAttributedString?)
            -> Cancellable where Source.Output == Sequence {
                return { attributedTitleForRow in
                    let adapter = CombineAttributedStringPickerViewAdapter<Sequence>(attributedTitleForRow: attributedTitleForRow)
                    return self.items(adapter: adapter)(source)
                }
        }
        
        /**
         Binds sequences of elements to picker view rows.
         
         - parameter source: Publisher sequence of items.
         - parameter viewForRow: Transform between sequence elements and row views.
         - returns: Cancellable object that can be used to unbind.
         
         Example:
         
         let items = Publisher.just([
                "First Item",
                "Second Item",
                "Third Item"
            ])
         
         items
            .bind(to: pickerView.cb.items) { (row, element, view) in
                guard let myView = view as? MyView else {
                    let view = MyView()
                    view.configure(with: element)
                    return view
                }
                myView.configure(with: element)
                return myView
            }
            .disposed(by: disposeBag)
         
         */

        public func items<Sequence: Swift.Sequence, Source: Publisher>
            (_ source: Source)
            -> (_ viewForRow: @escaping (Int, Sequence.Element, UIView?) -> UIView)
            -> Cancellable where Source.Output == Sequence {
                return { viewForRow in
                    let adapter = CombinePickerViewAdapter<Sequence>(viewForRow: viewForRow)
                    return self.items(adapter: adapter)(source)
                }
        }
        
        /**
         Binds sequences of elements to picker view rows using a custom reactive adapter used to perform the transformation.
         This method will retain the adapter for as long as the subscription isn't disposed (result `Cancellable`
         being disposed).
         In case `source` observable sequence terminates successfully, the adapter will present latest element
         until the subscription isn't disposed.
         
         - parameter adapter: Adapter used to transform elements to picker components.
         - parameter source: Publisher sequence of items.
         - returns: Cancellable object that can be used to unbind.
         */
        public func items<Source: Publisher,
                          Adapter: CombinePickerViewDataSourceType & UIPickerViewDataSource & UIPickerViewDelegate>(adapter: Adapter)
            -> (_ source: Source)
            -> Cancellable where Source.Output == Adapter.Element {
                return { source in
                    let delegateSubscription = self.setDelegate(adapter)
                    let dataSourceSubscription = source.subscribeProxyDataSource(ofObject: self.base, dataSource: adapter, retainDataSource: true, binding: { [weak pickerView = self.base] (_: CombinePickerViewDataSourceProxy, event) in
                        guard let pickerView = pickerView else { return }
                        adapter.pickerView(pickerView, observed: event)
										}, completion: {_, _ in })
									return AnyCancellable {
										delegateSubscription.cancel()
										dataSourceSubscription.cancel()
									}
                }
        }
        
        /**
         Synchronous helper method for retrieving a model at indexPath through a reactive data source.
         */
        public func model<T>(at indexPath: IndexPath) throws -> T {
            let dataSource: SectionedViewDataSourceType = castOrFatalError(self.dataSource.forwardToDelegate(), message: "This method only works in case one of the `rx.itemTitles, rx.itemAttributedTitles, items(_ source: O)` methods was used.")
            
            return castOrFatalError(try dataSource.model(at: indexPath))
        }
    }

#endif
