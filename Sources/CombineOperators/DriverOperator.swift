import Combine

infix operator ==> : CombinePrecedence

// MARK: - Simple subscribe

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure {
    lhs.asDriver().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == Error {
    lhs.asDriver().eraseFailure().subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never {
    lhs.asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure {
    lhs.asDriver().optional().subscribe(rhs)
}

/// - Warning: When passing a closure that captures `self`, be sure to use a `[weak self]` capture list to avoid retain cycles or wrap the closure in a `Binder` subscriber.
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
