//
//  DelegateProxyType.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 6/15/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if !os(Linux)

    import Foundation
    import Combine

/**
`DelegateProxyType` protocol enables using both normal delegates and Combine observable sequences with
views that can have only one delegate/datasource registered.

`Proxies` store information about observers, subscriptions and delegates
for specific views.

Type implementing `DelegateProxyType` should never be initialized directly.

To fetch initialized instance of type implementing `DelegateProxyType`, `proxy` method
should be used.

This is more or less how it works.



      +-------------------------------------------+
      |                                           |                           
      | UIView subclass (UIScrollView)            |                           
      |                                           |
      +-----------+-------------------------------+                           
                  |                                                           
                  | Delegate                                                  
                  |                                                           
                  |                                                           
      +-----------v-------------------------------+                           
      |                                           |                           
      | Delegate proxy : DelegateProxyType        +-----+---->  AnyPublisher<T1, Error>
      |                , UIScrollViewDelegate     |     |
      +-----------+-------------------------------+     +---->  AnyPublisher<T2, Error>
                  |                                     |                     
                  |                                     +---->  AnyPublisher<T3, Error>
                  |                                     |                     
                  | forwards events                     |
                  | to custom delegate                  |
                  |                                     v                     
      +-----------v-------------------------------+                           
      |                                           |                           
      | Custom delegate (UIScrollViewDelegate)    |                           
      |                                           |
      +-------------------------------------------+                           


Since CombineCocoa needs to automagically create those Proxys and because views that have delegates can be hierarchical

     UITableView : UIScrollView : UIView

.. and corresponding delegates are also hierarchical

     UITableViewDelegate : UIScrollViewDelegate : NSObject

... this mechanism can be extended by using the following snippet in `registerKnownImplementations` or in some other
     part of your app that executes before using `rx.*` (e.g. appDidFinishLaunching).

    CombineScrollViewDelegateProxy.register { CombineTableViewDelegateProxy(parentObject: $0) }

*/
@available(iOS 13.0, macOS 10.15, *)
public protocol DelegateProxyType: AnyObject {
    associatedtype ParentObject: AnyObject
    associatedtype Delegate
    
    /// It is require that enumerate call `register` of the extended DelegateProxy subclasses here.
    static func registerKnownImplementations()

    /// Unique identifier for delegate
    static var identifier: UnsafeRawPointer { get }

    /// Returns designated delegate property for object.
    ///
    /// Objects can have multiple delegate properties.
    ///
    /// Each delegate property needs to have it's own type implementing `DelegateProxyType`.
    ///
    /// It's abstract method.
    ///
    /// - parameter object: Object that has delegate property.
    /// - returns: Value of delegate property.
    static func currentDelegate(for object: ParentObject) -> Delegate?

    /// Sets designated delegate property for object.
    ///
    /// Objects can have multiple delegate properties.
    ///
    /// Each delegate property needs to have it's own type implementing `DelegateProxyType`.
    ///
    /// It's abstract method.
    ///
    /// - parameter toObject: Object that has delegate property.
    /// - parameter delegate: Delegate value.
    static func setCurrentDelegate(_ delegate: Delegate?, to object: ParentObject)

    /// Returns reference of normal delegate that receives all forwarded messages
    /// through `self`.
    ///
    /// - returns: Value of reference if set or nil.
    func forwardToDelegate() -> Delegate?

    /// Sets reference of normal delegate that receives all forwarded messages
    /// through `self`.
    ///
    /// - parameter forwardToDelegate: Reference of delegate that receives all messages through `self`.
    /// - parameter retainDelegate: Should `self` retain `forwardToDelegate`.
    func setForwardToDelegate(_ forwardToDelegate: Delegate?, retainDelegate: Bool)
}

// default implementations
@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType {
    /// Unique identifier for delegate
    public static var identifier: UnsafeRawPointer {
        let delegateIdentifier = ObjectIdentifier(Delegate.self)
        let integerIdentifier = Int(bitPattern: delegateIdentifier)
        return UnsafeRawPointer(bitPattern: integerIdentifier)!
    }
}

// workaround of Delegate: class
@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType {
    static func _currentDelegate(for object: ParentObject) -> AnyObject? {
        currentDelegate(for: object).map { $0 as AnyObject }
    }
    
    static func _setCurrentDelegate(_ delegate: AnyObject?, to object: ParentObject) {
        setCurrentDelegate(castOptionalOrFatalError(delegate), to: object)
    }
    
    func _forwardToDelegate() -> AnyObject? {
        self.forwardToDelegate().map { $0 as AnyObject }
    }
    
    func _setForwardToDelegate(_ forwardToDelegate: AnyObject?, retainDelegate: Bool) {
        self.setForwardToDelegate(castOptionalOrFatalError(forwardToDelegate), retainDelegate: retainDelegate)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType {

    /// Store DelegateProxy subclass to factory.
    /// When make 'Combine*DelegateProxy' subclass, call 'Combine*DelegateProxySubclass.register(for:_)' 1 time, or use it in DelegateProxyFactory
    /// 'Combine*DelegateProxy' can have one subclass implementation per concrete ParentObject type.
    /// Should call it from concrete DelegateProxy type, not generic.
    public static func register<Parent>(make: @escaping (Parent) -> Self) {
        self.factory.extend(make: make)
    }

    /// Creates new proxy for target object.
    /// Should not call this function directory, use 'DelegateProxy.proxy(for:)'
    public static func createProxy(for object: AnyObject) -> Self {
        castOrFatalError(factory.createProxy(for: object))
    }

    /// Returns existing proxy for object or installs new instance of delegate proxy.
    ///
    /// - parameter object: Target object on which to install delegate proxy.
    /// - returns: Installed instance of delegate proxy.
    ///
    ///
    ///     extension Reactive where Base: UISearchBar {
    ///
    ///         public var delegate: DelegateProxy<UISearchBar, UISearchBarDelegate> {
    ///            return CombineSearchBarDelegateProxy.proxy(for: base)
    ///         }
    ///
    ///         public var text: ControlProperty<String> {
    ///             let source: AnyPublisher<String, Error> = self.delegate.observe(#selector(UISearchBarDelegate.searchBar(_:textDidChange:)))
    ///             ...
    ///         }
    ///     }
    public static func proxy(for object: ParentObject) -> Self {
        DispatchQueue.ensureRunningOnMainThread()

        let maybeProxy = self.assignedProxy(for: object)

        let proxy: AnyObject
        if let existingProxy = maybeProxy {
            proxy = existingProxy
        }
        else {
            proxy = castOrFatalError(self.createProxy(for: object))
            self.assignProxy(proxy, toObject: object)
            assert(self.assignedProxy(for: object) === proxy)
        }
        let currentDelegate = self._currentDelegate(for: object)
        let delegateProxy: Self = castOrFatalError(proxy)

        if currentDelegate !== delegateProxy {
            delegateProxy._setForwardToDelegate(currentDelegate, retainDelegate: false)
            assert(delegateProxy._forwardToDelegate() === currentDelegate)
            self._setCurrentDelegate(proxy, to: object)
            assert(self._currentDelegate(for: object) === proxy)
            assert(delegateProxy._forwardToDelegate() === currentDelegate)
        }

        return delegateProxy
    }

    /// Sets forward delegate for `DelegateProxyType` associated with a specific object and return disposable that can be used to unset the forward to delegate.
    /// Using this method will also make sure that potential original object cached selectors are cleared and will report any accidental forward delegate mutations.
    ///
    /// - parameter forwardDelegate: Delegate object to set.
    /// - parameter retainDelegate: Retain `forwardDelegate` while it's being set.
    /// - parameter onProxyForObject: Object that has `delegate` property.
    /// - returns: Cancellable object that can be used to clear forward delegate.
	@available(iOS 13.0, macOS 10.15, *)
    public static func installForwardDelegate(_ forwardDelegate: Delegate, retainDelegate: Bool, onProxyForObject object: ParentObject) -> Cancellable {
        weak var weakForwardDelegate: AnyObject? = forwardDelegate as AnyObject
        let proxy = self.proxy(for: object)

        assert(proxy._forwardToDelegate() === nil, "This is a feature to warn you that there is already a delegate (or data source) set somewhere previously. The action you are trying to perform will clear that delegate (data source) and that means that some of your features that depend on that delegate (data source) being set will likely stop working.\n" +
            "If you are ok with this, try to set delegate (data source) to `nil` in front of this operation.\n" +
            " This is the source object value: \(object)\n" +
            " This is the original delegate (data source) value: \(proxy.forwardToDelegate()!)\n" +
            "Hint: Maybe delegate was already set in xib or storyboard and now it's being overwritten in code.\n")

        proxy.setForwardToDelegate(forwardDelegate, retainDelegate: retainDelegate)

        return AnyCancellable {
            DispatchQueue.ensureRunningOnMainThread()

            let delegate: AnyObject? = weakForwardDelegate

            assert(delegate == nil || proxy._forwardToDelegate() === delegate, "Delegate was changed from time it was first set. Current \(String(describing: proxy.forwardToDelegate())), and it should have been \(proxy)")

            proxy.setForwardToDelegate(nil, retainDelegate: retainDelegate)
        }
    }
}


// private extensions
@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType {
    private static var factory: DelegateProxyFactory {
        DelegateProxyFactory.sharedFactory(for: self)
    }

    private static func assignedProxy(for object: ParentObject) -> AnyObject? {
        let maybeDelegate = objc_getAssociatedObject(object, self.identifier)
        return castOptionalOrFatalError(maybeDelegate)
    }

    private static func assignProxy(_ proxy: AnyObject, toObject object: ParentObject) {
        objc_setAssociatedObject(object, self.identifier, proxy, .OBJC_ASSOCIATION_RETAIN)
    }
}

/// Describes an object that has a delegate.
@available(iOS 13.0, macOS 10.15, *)
public protocol HasDelegate: AnyObject {
    /// Delegate type
    associatedtype Delegate

    /// Delegate
    var delegate: Delegate? { get set }
}

@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType where ParentObject: HasDelegate, Self.Delegate == ParentObject.Delegate {
    public static func currentDelegate(for object: ParentObject) -> Delegate? {
        object.delegate
    }

    public static func setCurrentDelegate(_ delegate: Delegate?, to object: ParentObject) {
        object.delegate = delegate
    }
}

/// Describes an object that has a data source.
@available(iOS 13.0, macOS 10.15, *)
public protocol HasDataSource: AnyObject {
    /// Data source type
    associatedtype DataSource

    /// Data source
    var dataSource: DataSource? { get set }
}

@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType where ParentObject: HasDataSource, Self.Delegate == ParentObject.DataSource {
    public static func currentDelegate(for object: ParentObject) -> Delegate? {
        object.dataSource
    }

    public static func setCurrentDelegate(_ delegate: Delegate?, to object: ParentObject) {
        object.dataSource = delegate
    }
}

/// Describes an object that has a prefetch data source.
@available(iOS 13.0, macOS 10.15, *)
public protocol HasPrefetchDataSource: AnyObject {
    /// Prefetch data source type
    associatedtype PrefetchDataSource

    /// Prefetch data source
    var prefetchDataSource: PrefetchDataSource? { get set }
}

@available(iOS 13.0, macOS 10.15, *)
extension DelegateProxyType where ParentObject: HasPrefetchDataSource, Self.Delegate == ParentObject.PrefetchDataSource {
    public static func currentDelegate(for object: ParentObject) -> Delegate? {
        object.prefetchDataSource
    }

    public static func setCurrentDelegate(_ delegate: Delegate?, to object: ParentObject) {
        object.prefetchDataSource = delegate
    }
}

    #if os(iOS) || os(tvOS)
        import UIKit

		@available(iOS 13.0, macOS 10.15, *)
        extension Publisher {
					func subscribeProxyDataSource<DelegateProxy: DelegateProxyType>(ofObject object: DelegateProxy.ParentObject, dataSource: DelegateProxy.Delegate, retainDataSource: Bool, binding: @escaping (DelegateProxy, Output) -> Void, completion: @escaping (DelegateProxy, Subscribers.Completion<Failure>) -> Void)
                -> Cancellable
                where DelegateProxy.ParentObject: UIView
                , DelegateProxy.Delegate: AnyObject {
                let proxy = DelegateProxy.proxy(for: object)
                let unregisterDelegate = DelegateProxy.installForwardDelegate(dataSource, retainDelegate: retainDataSource, onProxyForObject: object)

                // Do not perform layoutIfNeeded if the object is still not in the view heirarchy
                if object.window != nil {
                    // this is needed to flush any delayed old state (https://github.com/CombineSwiftCommunity/CombineDataSources/pull/75)
                    object.layoutIfNeeded()
                }

                let subscription = self
									.receive(on: DispatchQueue.main)
									.catch { error -> Empty<Output, Failure> in
                        bindingError(error)
                        return Empty(completeImmediately: true)
                    }
                    // source can never end, otherwise it would release the subscriber, and deallocate the data source
									.append(Empty<Output, Failure>(completeImmediately: false))
                    .prefix(untilOutputFrom: object.cb.deallocated)
									.sink(
										receiveCompletion: { [weak object] c in
											if let object = object {
												assert(proxy === DelegateProxy.currentDelegate(for: object), "Proxy changed from the time it was first set.\nOriginal: \(proxy)\nExisting: \(String(describing: DelegateProxy.currentDelegate(for: object)))")
											}
											
											completion(proxy, c)
											switch c {
											case .failure(let error):
												bindingError(error)
												unregisterDelegate.cancel()
											case .finished:
												unregisterDelegate.cancel()
											}
										},
										receiveValue: { [weak object] value in
											if let object = object {
												assert(proxy === DelegateProxy.currentDelegate(for: object), "Proxy changed from the time it was first set.\nOriginal: \(proxy)\nExisting: \(String(describing: DelegateProxy.currentDelegate(for: object)))")
											}
											
											binding(proxy, value)
										}
									)
                    
                return AnyCancellable { [weak object] in
                    subscription.cancel()
                    if object?.window != nil {
                        object?.layoutIfNeeded()
                    }
                    unregisterDelegate.cancel()
                }
            }
        }

    #endif

    /**

     To add delegate proxy subclasses call `DelegateProxySubclass.register()` in `registerKnownImplementations` or in some other
     part of your app that executes before using `rx.*` (e.g. appDidFinishLaunching).

         class CombineScrollViewDelegateProxy: DelegateProxy {
             public static func registerKnownImplementations() {
                 self.register { CombineTableViewDelegateProxy(parentObject: $0) }
         }
         ...


     */
@available(iOS 13.0, macOS 10.15, *)
    private class DelegateProxyFactory {
        private static var _sharedFactories: [UnsafeRawPointer: DelegateProxyFactory] = [:]

        fileprivate static func sharedFactory<DelegateProxy: DelegateProxyType>(for proxyType: DelegateProxy.Type) -> DelegateProxyFactory {
            DispatchQueue.ensureRunningOnMainThread()
            let identifier = DelegateProxy.identifier
            if let factory = _sharedFactories[identifier] {
                return factory
            }
            let factory = DelegateProxyFactory(for: proxyType)
            _sharedFactories[identifier] = factory
            DelegateProxy.registerKnownImplementations()
            return factory
        }

        private var _factories: [ObjectIdentifier: ((AnyObject) -> AnyObject)]
        private var _delegateProxyType: Any.Type
        private var _identifier: UnsafeRawPointer

        private init<DelegateProxy: DelegateProxyType>(for proxyType: DelegateProxy.Type) {
            self._factories = [:]
            self._delegateProxyType = proxyType
            self._identifier = proxyType.identifier
        }

        fileprivate func extend<DelegateProxy: DelegateProxyType, ParentObject>(make: @escaping (ParentObject) -> DelegateProxy) {
                DispatchQueue.ensureRunningOnMainThread()
                precondition(self._identifier == DelegateProxy.identifier, "Delegate proxy has inconsistent identifier")
                guard self._factories[ObjectIdentifier(ParentObject.self)] == nil else {
                    rxFatalError("The factory of \(ParentObject.self) is duplicated. DelegateProxy is not allowed of duplicated base object type.")
                }
                self._factories[ObjectIdentifier(ParentObject.self)] = { make(castOrFatalError($0)) }
        }

        fileprivate func createProxy(for object: AnyObject) -> AnyObject {
            DispatchQueue.ensureRunningOnMainThread()
            var maybeMirror: Mirror? = Mirror(reflecting: object)
            while let mirror = maybeMirror {
                if let factory = self._factories[ObjectIdentifier(mirror.subjectType)] {
                    return factory(object)
                }
                maybeMirror = mirror.superclassMirror
            }
            rxFatalError("DelegateProxy has no factory of \(object). Implement DelegateProxy subclass for \(object) first.")
        }
    }

#endif
