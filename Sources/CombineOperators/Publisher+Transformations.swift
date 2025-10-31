import Combine
import Foundation

public extension Publisher {

	/// Emits values at regular intervals.
	///
	/// Combines publisher with timer, emitting original values at specified rate.
	func interval(_ period: TimeInterval, runLoop: RunLoop = .main) -> AnyPublisher<Output, Never> {
		skipFailure()
			.zip(
				Timer.TimerPublisher(interval: period, runLoop: runLoop, mode: .default)
					.autoconnect()
					.prepend(Date())
			)
			.map { $0.0 }
			.eraseToAnyPublisher()
	}

	/// Emits tuples of (previous, current) values with initial value.
	///
	/// ```swift
	/// numbers.withLast(initial: 0)  // (0,1), (1,2), (2,3)
	/// ```
	func withLast(initial value: Output) -> Publishers.Scan<Self, (previous: Output, current: Output)> {
		scan((value, value)) { ($0.1, $1) }
	}

	/// Emits (previous?, current) tuples. First emission has nil previous.
	///
	/// ```swift
	/// numbers.withLast()  // (nil,1), (1,2), (2,3)
	/// ```
	func withLast() -> Publishers.WithLast<Self> {
		scan((nil, nil)) { ($0.1, $1) }.map { ($0.0, $0.1!) }
	}

	/// Maps all outputs to a constant value.
	///
	/// ```swift
	/// buttonTap.value("clicked")  // emits "clicked" for each tap
	/// ```
	func value<T>(_ value: T) -> Publishers.Map<Self, T> {
		map { _ in value }
	}

	/// Shorthand for `eraseToAnyPublisher()`.
	@inlinable
	func any() -> AnyPublisher<Output, Failure> {
		eraseToAnyPublisher()
	}

	/// Appends values to the end of the publisher sequence.
	///
	/// ```swift
	/// publisher.append(1, 2, 3)
	/// ```
	func append(_ values: Output...) -> Publishers.Concatenate<Self, Publishers.Sequence<[Output], Failure>> {
		append(Publishers.Sequence(sequence: values))
	}

	/// Emits value with boolean indicating if keyPath value changed.
	///
	/// ```swift
	/// users.andIsSame(\.id)  // (user, didIdChange: Bool)
	/// ```
	func andIsSame<T: Equatable>(_ keyPath: KeyPath<Output, T>) -> Publishers.Map<Publishers.WithLast<Self>, (Self.Output, Bool)> {
		withLast().map {
			($0.1, $0.0?[keyPath: keyPath] == $0.1[keyPath: keyPath])
		}
	}
}
