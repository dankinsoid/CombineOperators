//
//  NSObject+Combine.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if !os(Linux)

import Foundation
import Combine
#if SWIFT_PACKAGE && !DISABLE_SWIZZLING && !os(Linux)
    import CombineCocoaRuntime
#endif

#if !DISABLE_SWIZZLING && !os(Linux)
private var deallocatingSubjectTriggerContext: UInt8 = 0
private var deallocatingSubjectContext: UInt8 = 0
#endif
private var deallocatedSubjectTriggerContext: UInt8 = 0
private var deallocatedSubjectContext: UInt8 = 0

#if !os(Linux)

/**
KVO is a tricky mechanism.

When observing child in a ownership hierarchy, usually retaining observing target is wanted behavior.
When observing parent in a ownership hierarchy, usually retaining target isn't wanter behavior.

KVO with weak references is especially tricky. For it to work, some kind of swizzling is required.
That can be done by
    * replacing object class dynamically (like KVO does)
    * by swizzling `dealloc` method on all instances for a class.
    * some third method ...

Both approaches can fail in certain scenarios:
    * problems arise when swizzlers return original object class (like KVO does when nobody is observing)
    * Problems can arise because replacing dealloc method isn't atomic operation (get implementation,
    set implementation).

Second approach is chosen. It can fail in case there are multiple libraries dynamically trying
to replace dealloc method. In case that isn't the case, it should be ok.
*/
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: NSObject {

    /**
    Observes values at the provided key path using the provided options.

     - parameter keyPath: A key path between the object and one of its properties.
     - parameter options: Key-value observation options, defaults to `.new` and `.initial`.

     - note: When the object is deallocated, a completion event is emitted.

     - returns: An observable emitting value changes at the provided key path.
    */
    public func observe<Element>(_ keyPath: KeyPath<Base, Element>,
                                 options: NSKeyValueObservingOptions = [.new, .initial]) -> NSObject.KeyValueObservingPublisher<Base, Element> {
			base.publisher(for: keyPath, options: options)
    }
}

#endif

// Dealloc
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: AnyObject {
    
    /**
    Publisher sequence of object deallocated events.
    
    After object is deallocated one `()` element will be produced and sequence will immediately complete.
    
    - returns: Publisher sequence of object deallocated events.
    */
    public var deallocated: AnyPublisher<Void, Never> {
        return self.synchronized {
            if let deallocPublisher = objc_getAssociatedObject(self.base, &deallocatedSubjectContext) as? DeallocPublisher {
							return deallocPublisher.subject.eraseToAnyPublisher()
            }

            let deallocPublisher = DeallocPublisher()

            objc_setAssociatedObject(self.base, &deallocatedSubjectContext, deallocPublisher, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
					return deallocPublisher.subject.eraseToAnyPublisher()
        }
    }

#if !DISABLE_SWIZZLING && !os(Linux)

    /**
     Publisher sequence of message arguments that completes when object is deallocated.
     
     Each element is produced before message is invoked on target object. `methodInvoked`
     exists in case observing of invoked messages is needed.

     In case an error occurs sequence will fail with `CombineCocoaObjCRuntimeError`.
     
     In case some argument is `nil`, instance of `NSNull()` will be sent.

     - returns: Publisher sequence of arguments passed to `selector` method.
     */
    public func sentMessage(_ selector: Selector) -> AnyPublisher<[Any], Error> {
        return self.synchronized {
            // in case of dealloc selector replay subject behavior needs to be used
            if selector == deallocSelector {
							return self.deallocating.map { _ in [] }.eraseToAnyPublisher()
            }

            do {
                let proxy: MessageSentProxy = try self.registerMessageInterceptor(selector)
							return proxy.messageSent.eraseToAnyPublisher()
            }
            catch let e {
							return Fail(error: e).eraseToAnyPublisher()
            }
        }
    }

    /**
     Publisher sequence of message arguments that completes when object is deallocated.

     Each element is produced after message is invoked on target object. `sentMessage`
     exists in case interception of sent messages before they were invoked is needed.

     In case an error occurs sequence will fail with `CombineCocoaObjCRuntimeError`.

     In case some argument is `nil`, instance of `NSNull()` will be sent.

     - returns: Publisher sequence of arguments passed to `selector` method.
     */
    public func methodInvoked(_ selector: Selector) -> AnyPublisher<[Any], Error> {
        return self.synchronized {
            // in case of dealloc selector replay subject behavior needs to be used
            if selector == deallocSelector {
							return self.deallocated.map { _ in [] }.setFailureType(to: Error.self).eraseToAnyPublisher()
            }


            do {
                let proxy: MessageSentProxy = try self.registerMessageInterceptor(selector)
                return proxy.methodInvoked.eraseToAnyPublisher()
            }
            catch let e {
                return Fail(error: e).eraseToAnyPublisher()
            }
        }
    }

    /**
    Publisher sequence of object deallocating events.
    
    When `dealloc` message is sent to `self` one `()` element will be produced and after object is deallocated sequence
    will immediately complete.
     
    In case an error occurs sequence will fail with `CombineCocoaObjCRuntimeError`.
    
    - returns: Publisher sequence of object deallocating events.
    */
    public var deallocating: AnyPublisher<(), Error> {
        return self.synchronized {
            do {
                let proxy: DeallocatingProxy = try self.registerMessageInterceptor(deallocSelector)
                return proxy.messageSent.setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            catch let e {
                return Fail(error: e).eraseToAnyPublisher()
            }
        }
    }

    private func registerMessageInterceptor<T: MessageInterceptorSubject>(_ selector: Selector) throws -> T {
        let rxSelector = RX_selector(selector)
        let selectorReference = RX_reference_from_selector(rxSelector)

        let subject: T
        if let existingSubject = objc_getAssociatedObject(self.base, selectorReference) as? T {
            subject = existingSubject
        }
        else {
            subject = T()
            objc_setAssociatedObject(
                self.base,
                selectorReference,
                subject,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }

        if subject.isActive {
            return subject
        }

        var error: NSError?
        let targetImplementation = RX_ensure_observing(self.base, selector, &error)
        if targetImplementation == nil {
            throw error?.rxCocoaErrorForTarget(self.base) ?? CombineCocoaError.unknown
        }

        subject.targetImplementation = targetImplementation!

        return subject
    }
#endif
}

// MARK: Message interceptors

#if !DISABLE_SWIZZLING && !os(Linux)

@available(iOS 13.0, macOS 10.15, *)
private protocol MessageInterceptorSubject: AnyObject {
        init()

        var isActive: Bool {
            get
        }

        var targetImplementation: IMP { get set }
    }

@available(iOS 13.0, macOS 10.15, *)
    private final class DeallocatingProxy
        : MessageInterceptorSubject
        , RXDeallocatingObserver {
        typealias Element = ()

        let messageSent = PassthroughSubject<Void, Never>()

        @objc var targetImplementation: IMP = RX_default_target_implementation()

        var isActive: Bool {
            return self.targetImplementation != RX_default_target_implementation()
        }

        init() {
        }

        @objc func deallocating() {
            self.messageSent.send()
        }

        deinit {
					self.messageSent.send(completion: .finished)
        }
    }

@available(iOS 13.0, macOS 10.15, *)
    private final class MessageSentProxy
        : MessageInterceptorSubject
        , RXMessageSentObserver {
        typealias Element = [AnyObject]

        let messageSent = PassthroughSubject<[Any], Error>()
        let methodInvoked = PassthroughSubject<[Any], Error>()

        @objc var targetImplementation: IMP = RX_default_target_implementation()

        var isActive: Bool {
            return self.targetImplementation != RX_default_target_implementation()
        }

        init() {
        }

        @objc func messageSent(withArguments arguments: [Any]) {
            self.messageSent.send(arguments)
        }

        @objc func methodInvoked(withArguments arguments: [Any]) {
            self.methodInvoked.send(arguments)
        }

        deinit {
					self.messageSent.send(completion: .finished)
            self.methodInvoked.send(completion: .finished)
        }
    }

#endif


@available(iOS 13.0, macOS 10.15, *)
private final class DeallocPublisher {
    let subject = PassthroughSubject<Void, Never>()

    init() {}

    deinit {
        self.subject.send()
        self.subject.send(completion: .finished)
    }
}

// MARK: Constants

private let deallocSelector = NSSelectorFromString("dealloc")

// MARK: AnyObject + Reactive
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: AnyObject {
    func synchronized<T>( _ action: () -> T) -> T {
        objc_sync_enter(self.base)
        let result = action()
        objc_sync_exit(self.base)
        return result
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: AnyObject {
    /**
     Helper to make sure that `Publisher` returned from `createCachedPublisher` is only created once.
     This is important because there is only one `target` and `action` properties on `NSControl` or `UIBarButtonItem`.
     */
    func lazyInstanceAnyPublisher<T>(_ key: UnsafeRawPointer, createCachedPublisher: () -> T) -> T {
        if let value = objc_getAssociatedObject(self.base, key) {
					return (value as! Wrapper<T>).t
        }
        
        let observable = createCachedPublisher()
        
        objc_setAssociatedObject(self.base, key, Wrapper(observable), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        return observable
    }
}

private final class Wrapper<T> {
	var t: T
	init(_ t: T) {
		self.t = t
	}
}

#endif
