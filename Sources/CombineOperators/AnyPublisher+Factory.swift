import Foundation
import Combine

extension AnyPublisher {

	/// Creates a publisher that emits a single value then completes.
	///
	/// ```swift
	/// AnyPublisher<Int, Never>.just(42)
	/// ```
	public static func just(_ value: Output) -> AnyPublisher {
		Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
	}

	/// Creates a publisher that never emits or completes.
	///
	/// Useful for placeholders or testing.
	public static var never: AnyPublisher {
		Empty(completeImmediately: false).eraseToAnyPublisher()
	}

	/// Creates a publisher from variadic values.
	///
	/// ```swift
	/// AnyPublisher<Int, Never>.from(1, 2, 3)
	/// ```
	public static func from(_ values: Output...) -> AnyPublisher {
		from(values)
	}

	/// Creates a publisher from a sequence.
	///
	/// ```swift
	/// AnyPublisher<Int, Never>.from([1, 2, 3])
	/// ```
	public static func from<S: Sequence>(_ values: S) -> AnyPublisher where S.Element == Output {
		Publishers.Sequence(sequence: values).eraseToAnyPublisher()
	}

	/// Creates a publisher that immediately fails.
	///
	/// ```swift
	/// AnyPublisher<Int, MyError>.failure(.notFound)
	/// ```
	public static func failure(_ failure: Failure) -> AnyPublisher {
		Result.Publisher(.failure(failure)).eraseToAnyPublisher()
	}

	/// Creates a publisher that completes immediately without emitting.
	public static var empty: AnyPublisher {
		Empty(completeImmediately: true).eraseToAnyPublisher()
	}
}
