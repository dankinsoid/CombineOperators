import Combine

/// Main thread delivery and replaying operator.
///
/// **Usage:**
/// ```swift
/// publisher ==> subscriber       // Main thread delivery
/// publisher ==> { print($0) }    // Closure called on main thread
/// ```
///
/// For duplicate removal, use `==>>` instead.
infix operator ==>: CombinePrecedence

// MARK: - Simple subscribe

/// Subscribes to a publisher with main thread delivery.
@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure {
    lhs.receive(on: MainScheduler.instance).subscribe(rhs)
}

/// Subscribes to a publisher with main thread delivery, converting failure to Error.
@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).eraseFailure().subscribe(rhs)
}

/// Subscribes a never-failing publisher with main thread delivery.
@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never {
	lhs.receive(on: MainScheduler.instance).setFailureType(to: O.Failure.self).subscribe(rhs)
}

/// Subscribes a publisher with main thread delivery, wrapping output in Optional.
@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure {
	lhs.receive(on: MainScheduler.instance).optional().subscribe(rhs)
}

/// Subscribes with a closure on the main actor.
///
/// Values are delivered on the main thread. The closure executes in main actor isolation.
///
/// - Warning: Use `[weak self]` capture list to avoid retain cycles, or wrap in `Binder` and use `=>` operator since `Binder` already enforces main thread delivery.
@inlinable
public func ==> <O: Publisher>(_ lhs: O, _ rhs: @escaping @MainActor (O.Output) -> Void) -> AnyCancellable {
	lhs.receive(on: MainScheduler.instance).sink(
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
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
	lhs.receive(on: MainScheduler.instance).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output, T.Failure == Never, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure {
	lhs.receive(on: MainScheduler.instance).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
	lhs.receive(on: MainScheduler.instance).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).eraseFailure().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).optional().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	lhs.receive(on: MainScheduler.instance).optional().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never {
	lhs.receive(on: MainScheduler.instance).optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure {
	lhs.receive(on: MainScheduler.instance).optional().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).optional().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	lhs.receive(on: MainScheduler.instance).optional().subscribe(rhs)
}

@inlinable
public func ==> <T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where O.Output == T.Output?, O.Failure == Error {
	lhs.receive(on: MainScheduler.instance).optional().eraseFailure().subscribe(rhs)
}
