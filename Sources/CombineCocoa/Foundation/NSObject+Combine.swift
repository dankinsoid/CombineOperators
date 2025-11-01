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

private final class Wrapper<T> {
	var value: T

	init(_ value: T) {
		self.value = value
	}
}

#endif
