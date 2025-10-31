import Combine
import Foundation

/// Result builder for composing multiple cancellables.
///
/// ```swift
/// let bag = AnyCancellable {
///     subscription1
///     subscription2
///     if condition {
///         subscription3
///     }
/// }
/// ```
@resultBuilder
public struct CancellableBuilder {

	@inlinable
	public static func buildBlock(_ components: Cancellable...) -> Cancellable {
		create(from: components)
	}

	@inlinable
	public static func buildArray(_ components: [Cancellable]) -> Cancellable {
		create(from: components)
	}

	@inlinable
	public static func buildEither(first component: Cancellable) -> Cancellable {
		component
	}

	@inlinable
	public static func buildEither(second component: Cancellable) -> Cancellable {
		component
	}

	@inlinable
	public static func buildOptional(_ component: Cancellable?) -> Cancellable {
		component ?? create(from: [])
	}

	@inlinable
	public static func buildLimitedAvailability(_ component: Cancellable) -> Cancellable {
		component
	}

	@inlinable
	public static func buildExpression(_ expression: Cancellable) -> Cancellable {
		expression
	}

	@inlinable
	public static func create(from: [Cancellable]) -> Cancellable {
		from.count == 1 ? from[0] : ManualAnyCancellable(from)
	}
}

public extension AnyCancellable {

	/// Creates cancellable from variadic list.
	///
	/// ```swift
	/// let bag = AnyCancellable(sub1, sub2, sub3)
	/// bag.cancel()  // cancels all
	/// ```
	convenience init(_ list: Cancellable...) {
		self.init(list)
	}

	/// Creates cancellable using result builder syntax.
	///
	/// ```swift
	/// let bag = AnyCancellable {
	///     publisher1.sink { }
	///     publisher2.sink { }
	/// }
	/// ```
	convenience init(@CancellableBuilder _ builder: () -> Cancellable) {
		self.init(builder())
	}

	/// Creates cancellable from a sequence.
	convenience init<S: Sequence>(_ sequence: S) where S.Element == Cancellable {
		self.init {
			sequence.forEach { $0.cancel() }
		}
	}
}

/// Combines two cancellables using `+` operator.
///
/// ```swift
/// let combined = subscription1 + subscription2
/// combined.cancel()  // cancels both
/// ```
public func + (_ lhs: Cancellable, _ rhs: Cancellable) -> Cancellable {
	ManualAnyCancellable(lhs, rhs)
}

/// Lightweight cancellable that executes custom cancellation logic.
public struct ManualAnyCancellable: Cancellable {

	private let cancelAction: () -> Void

	public init() {
		cancelAction = {}
	}

	public init(_ cancelAction: @escaping () -> Void) {
		self.cancelAction = cancelAction
	}

	public init(_ cancellables: Cancellable...) {
		self.init(cancellables)
	}

	public init<S: Sequence>(_ sequence: S) where S.Element == Cancellable {
		cancelAction = {
			sequence.forEach { $0.cancel() }
		}
	}

	public func cancel() {
		cancelAction()
	}
}
