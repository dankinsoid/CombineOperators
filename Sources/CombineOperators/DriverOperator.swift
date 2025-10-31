import Combine

/// Thread-safe subscription operator with Driver semantics.
///
/// The `==>` operator converts publishers to Drivers before subscribing,
/// ensuring main thread delivery and replay on subscription.
///
/// **Usage:**
/// ```swift
/// publisher ==> subscriber       // Main thread delivery
/// publisher ==> { print($0) }    // Closure called on main thread
/// ```
///
/// **Driver guarantees:**
/// - Values delivered on main thread
/// - Last value replayed to new subscribers
/// - Never fails (errors are handled)
///
/// For duplicate removal, use `==>>` instead.
infix operator ==> : CombinePrecedence

// MARK: - Simple subscribe

/// Subscribes to a publisher as a Driver.
///
/// Converts the publisher to a Driver for thread-safe, main-queue delivery.
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure {
    lhs.asDriver().subscribe(rhs)
}

/// Subscribes as Driver, converting failure to Error.
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == Error {
    lhs.asDriver().eraseFailure().subscribe(rhs)
}

/// Subscribes a never-failing publisher as Driver.
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never {
    lhs.asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

/// Subscribes as Driver, wrapping output in Optional.
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure {
    lhs.asDriver().optional().subscribe(rhs)
}

/// Subscribes with a closure on the main actor.
///
/// Values are delivered on the main thread. The closure executes in main actor isolation.
///
/// - Warning: Use `[weak self]` capture list to avoid retain cycles, or wrap in `Binder`.
@inlinable
public func ==><O: Publisher>(_ lhs: O, _ rhs: @escaping @MainActor (O.Output) -> Void) -> AnyCancellable {
    lhs.asDriver().sink(
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
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.asDriver().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.asDriver().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never, O.Failure == Error {
    lhs.asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure {
    lhs.asDriver().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.asDriver().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.asDriver().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == Error {
    lhs.asDriver().eraseFailure().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == Error {
    lhs.asDriver().eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never {
    lhs.asDriver().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
    lhs.asDriver().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure {
    lhs.asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == Error {
    lhs.asDriver().optional().eraseFailure().subscribe(rhs)
}
