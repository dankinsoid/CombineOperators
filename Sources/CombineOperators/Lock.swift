import Foundation
import os

/// Thread-safe lock using `os_unfair_lock` for performance.
package final class Lock {

	private var _lock = os_unfair_lock()

	init() {
		_lock = os_unfair_lock()
	}

	func lock() {
		os_unfair_lock_lock(&_lock)
	}

	func unlock() {
		os_unfair_lock_unlock(&_lock)
	}

	func withLock<T>(_ action: () throws -> T) rethrows -> T {
		lock()
		defer { unlock() }
		return try action()
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

	package convenience init() where Value: ExpressibleByNilLiteral {
		self.init(wrappedValue: nil)
	}
}
