#if !os(Linux)
import Foundation
import Combine

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
extension Reactive where Base: NSObject {

    /**
    Observes values at the provided key path using the provided options.

     - parameter keyPath: A key path between the object and one of its properties.
     - parameter options: Key-value observation options, defaults to `.new` and `.initial`.

     - note: When the object is deallocated, a completion event is emitted.

     - returns: An observable emitting value changes at the provided key path.
    */
    public func observe<Element>(
        _ keyPath: KeyPath<Base, Element>,
        options: NSKeyValueObservingOptions = [.new, .initial]
    ) -> NSObject.KeyValueObservingPublisher<Base, Element> {
        base.publisher(for: keyPath, options: options)
    }
}

#endif

// Dealloc
extension Reactive where Base: AnyObject {
    
    /**
    Publisher sequence of object deallocated events.
    
    After object is deallocated one `()` element will be produced and sequence will immediately complete.
    
    - returns: Publisher sequence of object deallocated events.
    */
    public var deallocated: AnyPublisher<Void, Never> {
        Publishers.Create { subscriber in
            if let value = objc_getAssociatedObject(self.base, &deallocatedKey) as? DeolocateSubscribers {
                value.subscribers.append(subscriber)
            } else {
                let subscribers = DeolocateSubscribers()
                subscribers.subscribers.append(subscriber)
                objc_setAssociatedObject(self.base, &deallocatedKey, subscribers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            return AnyCancellable {
                objc_setAssociatedObject(self.base, &deallocatedKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
        .eraseToAnyPublisher()
    }
}

private var deallocatedKey = 0

extension Reactive where Base: AnyObject {
    
    /**
     Helper to make sure that `Publisher` returned from `createCachedPublisher` is only created once.
     This is important because there is only one `target` and `action` properties on `NSControl` or `UIBarButtonItem`.
     */
    func lazyInstanceAnyPublisher<T>(_ key: UnsafeRawPointer, createCachedPublisher: () -> T) -> T {
        if let value = objc_getAssociatedObject(self.base, key) {
            return (value as! Wrapper<T>).value
        }
        
        let observable = createCachedPublisher()
        objc_setAssociatedObject(self.base, key, Wrapper(observable), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return observable
    }
}

private final class DeolocateSubscribers {
    
    var subscribers: [AnySubscriber<Void, Never>] = []
    
    deinit {
        subscribers.forEach {
            _ = $0.receive(())
            $0.receive(completion: .finished)
        }
    }
}

private final class Wrapper<T> {
	var value: T
    
	init(_ value: T) {
		self.value = value
	}
}

#endif
