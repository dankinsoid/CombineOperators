import Combine

infix operator => : CombinePrecedence

// MARK: - Simple subscribe

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure {
    lhs.subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == Error {
    lhs.eraseFailure().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never {
    lhs.setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure {
    lhs.optional().subscribe(rhs)
}

/// - Warning: When passing a closure that captures `self`, be sure to use a `[weak self]` capture list to avoid retain cycles or wrap the closure in a `Binder` subscriber.
@inlinable
public func =><O: Publisher>(_ lhs: O, _ rhs: @escaping (O.Output) -> Void) -> AnyCancellable {
    lhs.sink(receiveCompletion: { _ in }, receiveValue: rhs)
}

// MARK: - Store in

@inlinable
public func =>(_ lhs: AnyCancellable, _ rhs: inout Set<AnyCancellable>) {
    lhs.store(in: &rhs)
}

@inlinable
public func =><R: RangeReplaceableCollection>(_ lhs: AnyCancellable, _ rhs: inout R) where R.Element == AnyCancellable {
    lhs.store(in: &rhs)
}

@inlinable
public func =><T: Publisher, S: Scheduler>(_ lhs: T, _ rhs: S) -> Publishers.SubscribeOn<T, S> {
    lhs.subscribe(on: rhs)
}

// MARK: - Prevent ambiguity

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never, O.Failure == Error {
    lhs.setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure {
    lhs.subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == Error {
    lhs.eraseFailure().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.optional().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.optional().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == Error {
    lhs.eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never {
    lhs.optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
    lhs.optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure {
    lhs.optional().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.optional().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.optional().subscribe(rhs)
}

@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == Error {
    lhs.optional().eraseFailure().subscribe(rhs)
}
