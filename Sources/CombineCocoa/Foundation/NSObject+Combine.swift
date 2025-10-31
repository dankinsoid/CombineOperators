#if !os(Linux)
import Combine
import Foundation

#if !os(Linux)

public extension Reactive where Base: NSObject {

	/// KVO publisher for property at keypath.
	///
	/// Completes when object deallocates. Defaults to emitting initial + new values.
	///
	/// ```swift
	/// view.cb.observe(\.frame)
	///     .sink { print("Frame: \($0)") }
	/// ```
	func observe<Element>(
		_ keyPath: KeyPath<Base, Element>,
		options: NSKeyValueObservingOptions = [.new, .initial]
	) -> NSObject.KeyValueObservingPublisher<Base, Element> {
		base.publisher(for: keyPath, options: options)
	}
}

#endif

/// Dealloc
public extension Reactive where Base: AnyObject {

	/// Emits once when object deallocates, then completes.
	///
	/// Useful for automatic cleanup:
	/// ```swift
	/// publisher.prefix(untilOutputFrom: view.cb.deallocated)
	/// ```
	var deallocated: AnyPublisher<Void, Never> {
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
	/// Caches publisher instance per object. Required for single target/action UI controls.
	func lazyInstanceAnyPublisher<T>(_ key: UnsafeRawPointer, createCachedPublisher: () -> T) -> T {
		if let value = objc_getAssociatedObject(base, key) {
			return (value as! Wrapper<T>).value
		}

		let observable = createCachedPublisher()
		objc_setAssociatedObject(base, key, Wrapper(observable), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return observable
	}
}

private final class DeolocateSubscribers {

	var subscribers: [AnySubscriber<Void, Never>] = []

	deinit {
		for subscriber in subscribers {
			_ = subscriber.receive(())
			subscriber.receive(completion: .finished)
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
