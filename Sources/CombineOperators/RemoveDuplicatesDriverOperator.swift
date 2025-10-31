import Combine

/// Thread-safe subscription operator with Driver semantics and duplicate removal.
///
/// The `==>>` operator combines Driver guarantees with automatic duplicate filtering.
/// Equivalent to `removeDuplicates().asDriver()`.
///
/// **Usage:**
/// ```swift
/// publisher ==>> subscriber       // Main thread + unique values
/// publisher ==>> { print($0) }    // Only distinct values on main thread
/// ```
///
/// **Guarantees:**
/// - Values delivered on main thread (Driver)
/// - Consecutive duplicates removed
/// - Last value replayed to new subscribers
/// - Never fails (errors are handled)
///
/// - Note: Requires `Equatable` output type.
infix operator ==>>: CombinePrecedence

// MARK: - Simple subscribe

/// Subscribes to a publisher as a Driver, removing consecutive duplicates.
@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure {
	lhs.removeDuplicates().asDriver().subscribe(rhs)
}

/// Subscribes as Driver with duplicate removal, converting failure to Error.
@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == Error {
	lhs.removeDuplicates().asDriver().eraseFailure().subscribe(rhs)
}

/// Subscribes a never-failing publisher as Driver with duplicate removal.
@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, T.Failure == Never {
	lhs.removeDuplicates().asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

/// Subscribes as Driver with duplicate removal, wrapping output in Optional.
@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure {
	lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

/// Subscribes with a closure on the main actor, removing duplicates.
///
/// Only distinct values are delivered. Closure executes in main actor isolation.
///
/// - Warning: Use `[weak self]` capture list to avoid retain cycles, or wrap in `Binder`.
@inlinable
public func ==>> <O: Publisher>(_ lhs: O, _ rhs: @escaping @MainActor (O.Output) -> Void) -> AnyCancellable where O.Output: Equatable {
	lhs.removeDuplicates().asDriver().removeDuplicates().asDriver().sink(
		receiveCompletion: { _ in },
		receiveValue: { input in
			MainActor.assumeIsolated {
				rhs(input)
			}
		}
	)
}

// MARK: - Prevent ambiguity

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
	lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
	lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, T.Failure == Never, O.Failure == Error {
	lhs.removeDuplicates().asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure {
	lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
	lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
	lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == Error {
	lhs.removeDuplicates().asDriver().eraseFailure().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == Error {
	lhs.removeDuplicates().asDriver().eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, T.Failure == Never {
	lhs.removeDuplicates().asDriver().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
	lhs.removeDuplicates().asDriver().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure {
	lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == Error {
	lhs.removeDuplicates().asDriver().optional().eraseFailure().subscribe(rhs)
}
