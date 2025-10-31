import Combine
import Foundation

// MARK: - Custom Publisher Operators

/// Negates boolean publisher output.
///
/// ```swift
/// let isHidden = isVisible.toggle()
/// // or
/// let isHidden = !isVisible
/// ```
public prefix func ! <O: Publisher>(_ rhs: O) -> Publishers.Map<O, Bool> where O.Output == Bool {
	rhs.map { !$0 }
}

/// Merges two publishers using `+` operator.
///
/// ```swift
/// let combined = publisherA + publisherB
/// ```
public func + <T: Publisher, O: Publisher>(_ lhs: T, _ rhs: O) -> Publishers.Merge<T, O> where O.Output == T.Output, O.Failure == T.Failure {
	lhs.merge(with: rhs)
}

/// Nil-coalescing operator for optional publishers.
///
/// ```swift
/// optionalPublisher ?? "default"
/// ```
public func ?? <O: Publisher, T>(_ lhs: O, _ rhs: @escaping @autoclosure () -> T) -> Publishers.Map<O, T> where O.Output == T? {
	lhs.map { $0 ?? rhs() }
}

/// Combines latest values using `&` operator.
///
/// ```swift
/// let combined = publisherA & publisherB  // (A, B)
/// ```
public func & <T1: Publisher, T2: Publisher>(_ lhs: T1, _ rhs: T2) -> Publishers.CombineLatest<T1, T2> where T1.Failure == T2.Failure {
	lhs.combineLatest(rhs)
}
