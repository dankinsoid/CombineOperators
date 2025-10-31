import Combine
import Foundation

public extension Publisher {

	/// Maps output to boolean indicating if value is nil.
	func isNil<T>() -> Publishers.Map<Self, Bool> where Output == T? {
		map { $0 == nil }
	}

	/// Filters out nil values, unwrapping non-nil values.
	///
	/// ```swift
	/// optionalPublisher.skipNil()  // Publisher<String, Never>
	/// ```
	func skipNil<T>() -> Publishers.SkipNil<Self, T> where Output == T? {
		Publishers.SkipNil(source: self)
	}

	/// Replaces nil values with a default.
	///
	/// ```swift
	/// optionalText.or("N/A")
	/// ```
	func or<T>(_ value: T) -> Publishers.Map<Self, T> where Output == T? {
		map { $0 ?? value }
	}

	/// Wraps output in Optional.
	func optional() -> Publishers.Map<Self, Output?> {
		map { $0 }
	}

	/// Returns true if value is nil or empty collection.
	func isNilOrEmpty<T: Collection>() -> Publishers.Map<Self, Bool> where Output == T? {
		map { $0?.isEmpty != false }
	}
}

public extension Publishers {

	/// Publisher that filters out nil values from optional publisher.
	struct SkipNil<P: Publisher, Output>: Publisher where P.Output == Output? {

		public typealias Failure = P.Failure
		public let source: P

		public func receive<S: Subscriber>(subscriber: S) where P.Failure == S.Failure, Output == S.Input {
			source.compactMap { $0 }.receive(subscriber: subscriber)
		}
	}
}
