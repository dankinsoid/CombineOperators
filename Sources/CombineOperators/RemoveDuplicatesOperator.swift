import Combine

/// Subscription operator with automatic duplicate removal.
///
/// The `=>>` operator applies `removeDuplicates()` before subscribing.
/// Does not enforce main thread delivery. For thread-safe variant, use `==>>`.
///
/// **Usage:**
/// ```swift
/// publisher =>> subscriber       // Removes consecutive duplicates
/// publisher =>> { print($0) }    // Closure receives unique values only
/// ```
///
/// - Note: Requires `Equatable` output type.
infix operator =>> : CombinePrecedence

// MARK: - Simple subscribe

/// Subscribes to a publisher, removing consecutive duplicates.
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure {
    lhs.removeDuplicates().subscribe(rhs)
}

/// Subscribes with duplicate removal, converting failure to Error.
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == Error {
    lhs.removeDuplicates().eraseFailure().subscribe(rhs)
}

/// Subscribes a never-failing publisher with duplicate removal.
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, T.Failure == Never {
    lhs.removeDuplicates().setFailureType(to: O.Failure.self).subscribe(rhs)
}

/// Subscribes with duplicate removal, wrapping output in Optional.
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure {
    lhs.removeDuplicates().optional().subscribe(rhs)
}

/// Subscribes with a closure, removing duplicates first.
///
/// - Warning: Use `[weak self]` capture list to avoid retain cycles, or wrap in `Binder`.
@inlinable
public func =>><O: Publisher>(_ lhs: O, _ rhs: @escaping (O.Output) -> Void) -> AnyCancellable where O.Output: Equatable {
    lhs.removeDuplicates().sink(receiveCompletion: { _ in }, receiveValue: rhs)
}

// MARK: - Prevent ambiguity

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, T.Failure == Never, O.Failure == Error {
    lhs.removeDuplicates().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure {
    lhs.removeDuplicates().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == Error {
    lhs.removeDuplicates().eraseFailure().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().optional().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().optional().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == Error {
    lhs.removeDuplicates().eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, T.Failure == Never {
    lhs.removeDuplicates().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
    lhs.removeDuplicates().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure {
    lhs.removeDuplicates().optional().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().optional().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().optional().subscribe(rhs)
}

@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == Error {
    lhs.removeDuplicates().optional().eraseFailure().subscribe(rhs)
}
