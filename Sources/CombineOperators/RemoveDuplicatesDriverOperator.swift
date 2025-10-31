import Combine

infix operator ==>> : CombinePrecedence

// MARK: - Simple subscribe

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure {
    lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == Error {
    lhs.removeDuplicates().asDriver().eraseFailure().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, T.Failure == Never {
    lhs.removeDuplicates().asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure {
    lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

/// - Warning: When passing a closure that captures `self`, be sure to use a `[weak self]` capture list to avoid retain cycles or wrap the closure in a `Binder` subscriber.
@inlinable
public func ==>><O: Publisher>(_ lhs: O, _ rhs: @escaping @MainActor (O.Output) -> Void) -> AnyCancellable where O.Output: Equatable {
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
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output, T.Failure == Never, O.Failure == Error {
    lhs.removeDuplicates().asDriver().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure {
    lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().asDriver().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output, O.Failure == Error {
    lhs.removeDuplicates().asDriver().eraseFailure().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, O.Failure == Error {
    lhs.removeDuplicates().asDriver().eraseFailure().optional().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, T.Failure == Never {
    lhs.removeDuplicates().asDriver().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T, _ rhs: O) where T.Output: Equatable, O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
    lhs.removeDuplicates().asDriver().optional().setFailureType(to: O.Failure.self).subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure {
    lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
    lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
    lhs.removeDuplicates().asDriver().optional().subscribe(rhs)
}

@inlinable
public func ==>><T: Publisher, O: Subject>(_ lhs: T, _ rhs: O) -> AnyCancellable where T.Output: Equatable, O.Output == T.Output?, O.Failure == Error {
    lhs.removeDuplicates().asDriver().optional().eraseFailure().subscribe(rhs)
}
