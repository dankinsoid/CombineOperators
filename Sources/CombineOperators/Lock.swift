import Foundation
import os

/// Thread-safe lock using `os_unfair_lock` for performance.
package final class Lock {

	private let p: UnsafeMutablePointer<os_unfair_lock> = {
		let p = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
		p.initialize(to: .init())
		return p
	}()

	public init() {}

	public func lock() {
		os_unfair_lock_lock(p)
	}

	public func unlock() {
		os_unfair_lock_unlock(p)
	}

	@discardableResult
	public func withLock<R>(_ body: () throws -> R) rethrows -> R {
		os_unfair_lock_lock(p)
		defer { os_unfair_lock_unlock(p) }
		return try body()
	}

	deinit {
		p.deinitialize(count: 1)
		p.deallocate()
	}
}

/// Property wrapper providing thread-safe access to wrapped value.
///
/// ```swift
/// @Locked var counter = 0
/// counter += 1  // thread-safe
/// ```
@propertyWrapper
package final class Locked<Value> {

	private let lock = Lock()
	private var value: Value

	package init(wrappedValue: Value) {
		value = wrappedValue
	}

	package init(_ value: Value) {
		self.value = value
	}

	package var wrappedValue: Value {
		_read {
			yield lock.withLock {
				value
			}
		}
		_modify {
			lock.lock()
			defer { lock.unlock() }
			yield &value
		}
	}

	package func withLock<T>(_ action: (inout Value) throws -> T) rethrows -> T {
		try lock.withLock {
			try action(&value)
		}
	}
}

package extension Locked {

	convenience init() where Value: ExpressibleByNilLiteral {
		self.init(wrappedValue: nil)
	}
}
