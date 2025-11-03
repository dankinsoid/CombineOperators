import Combine

/// Basic subscription operator without thread-safety guarantees.
///
/// The `=>` operator connects publishers to subscribers with automatic type conversions.
/// Unlike `==>` this operator does not enforce main thread delivery.
///
/// **Usage:**
/// ```swift
/// publisher => subscriber
/// publisher => { print($0) }
/// cancellable => &cancellables
/// ```
infix operator =>: CombinePrecedence

// MARK: - Simple subscribe

/// Subscribes to a publisher.
///
/// Connects a publisher to a subscriber when types match exactly.
@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure {
	lhs.subscribe(rhs)
}

/// Subscribes to a publisher, converting failure to Error.
@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == Error {
	lhs.eraseFailure().subscribe(rhs)
}

/// Subscribes a never-failing publisher to a fallible subscriber.
@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never {
	lhs.setFailureType(to: O.Failure.self).subscribe(rhs)
}

/// Subscribes to a publisher, wrapping output in Optional.
@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure {
	lhs.optional().subscribe(rhs)
}

/// Subscribes with a closure, ignoring completion events.
///
/// - Warning: Use `[weak self]` capture list to avoid retain cycles, or wrap in `Binder`.
@inlinable
public func => <O: Publisher>(_ lhs: O, _ rhs: @escaping (O.Output) -> Void) -> AnyCancellable {
	lhs.sink(receiveCompletion: { _ in }, receiveValue: rhs)
}

// MARK: - Store in

/// Stores a cancellable in a Set.
///
/// ```swift
/// publisher.sink { } => &cancellables
/// ```
@inlinable
public func => (_ lhs: AnyCancellable, _ rhs: inout Set<AnyCancellable>) {
	lhs.store(in: &rhs)
}

/// Stores a cancellable in any collection.
@inlinable
public func => <R: RangeReplaceableCollection>(_ lhs: AnyCancellable, _ rhs: inout R) where R.Element == AnyCancellable {
	lhs.store(in: &rhs)
}

/// Subscribes on a specific scheduler.
///
/// ```swift
/// publisher => DispatchQueue.global()
/// ```
@inlinable
public func => <T: Publisher, S: Scheduler>(_ lhs: T, _ rhs: S) -> Publishers.SubscribeOn<T, S> {
	lhs.subscribe(on: rhs)
}

// MARK: - Prevent ambiguity

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
	lhs.subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
	lhs.subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never, O.Failure == Error {
	lhs.setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure {
	lhs.subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
	lhs.subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
	lhs.subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == Error {
	lhs.eraseFailure().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	lhs.optional().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	lhs.optional().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == Error {
	lhs.eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never {
	lhs.optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
	lhs.optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure {
	lhs.optional().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	lhs.optional().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	lhs.optional().subscribe(rhs)
}

@inlinable
public func => <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == Error {
	lhs.optional().eraseFailure().subscribe(rhs)
}
