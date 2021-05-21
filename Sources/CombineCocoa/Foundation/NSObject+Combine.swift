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
import VDKit

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
			Publishers.Create { subscriber in
				AnyCancellable(onDeallocated(base, action: {
					_ = subscriber.receive(())
				}))
			}.eraseToAnyPublisher()
    }
}
#if !DISABLE_SWIZZLING && !os(Linux)

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: NSObjectProtocol {
    /**
     Publisher sequence of message arguments that completes when object is deallocated.
     
     Each element is produced before message is invoked on target object. `methodInvoked`
     exists in case observing of invoked messages is needed.

     In case an error occurs sequence will fail with `CombineCocoaObjCRuntimeError`.
     
     In case some argument is `nil`, instance of `NSNull()` will be sent.

     - returns: Publisher sequence of arguments passed to `selector` method.
     */
    public func sentMessage(_ selector: Selector) -> AnyPublisher<[Any], Error> {
			Publishers.Create { subscriber in
				do {
					return try AnyCancellable(base.onSentMessage(selector) {
					_ = subscriber.receive($0)
					})
				} catch {
					subscriber.receive(completion: .failure(error))
					return AnyCancellable()
				}
			}.eraseToAnyPublisher()
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
			Publishers.Create { subscriber in
				do {
					return try AnyCancellable(base.onMethodInvoked(selector) {
						_ = subscriber.receive($0)
					})
				} catch {
					subscriber.receive(completion: .failure(error))
					return AnyCancellable()
				}
			}.eraseToAnyPublisher()
    }

    /**
    Publisher sequence of object deallocating events.
    
    When `dealloc` message is sent to `self` one `()` element will be produced and after object is deallocated sequence
    will immediately complete.
     
    In case an error occurs sequence will fail with `CombineCocoaObjCRuntimeError`.
    
    - returns: Publisher sequence of object deallocating events.
    */
    public var deallocating: AnyPublisher<(), Error> {
			Publishers.Create { subscriber in
				do {
					return try AnyCancellable(base.onDeallocating {
						_ = subscriber.receive(())
					})
				} catch {
					subscriber.receive(completion: .failure(error))
					return AnyCancellable()
				}
			}.eraseToAnyPublisher()
    }
}
#endif

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
