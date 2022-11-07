import Foundation
import Combine

infix operator ==>>: CombinePrecedence
infix operator =>> : CombinePrecedence

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == T.Failure, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == Error, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().simpleError().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == Never, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipFailure().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, T.Failure == Never, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().setFailureType(to: O.Failure.self).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, T.Failure == Never, O.Failure == Error, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().setFailureType(to: O.Failure.self).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == T.Failure, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == Error, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().simpleError().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == Never, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipFailure().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><O: Publisher>(_ lhs: O?, _ rhs: @escaping (O.Output) -> Void) where O.Output: Equatable {
	lhs?.removeDuplicates().subscribe(AnySubscriber.create(rhs))
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><O: Publisher>(_ lhs: O?, _ rhs: @escaping @autoclosure () -> Void) where O.Output: Equatable {
	lhs =>> {_ in rhs() }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><O: Publisher>(_ lhs: O?, _ rhs: [(O.Output) -> ()]) where O.Output: Equatable {
	rhs.forEach { lhs?.removeDuplicates().subscribe(AnySubscriber.create($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Input: Equatable {
	rhs.map { lhs?.skipFailure().removeDuplicates().setFailureType(to: O.Failure.self).receive(on: RunLoop.main).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==>><O: Publisher>(_ lhs: O?, _ rhs: @escaping @autoclosure () -> Void) where O.Output: Equatable {
	lhs ==>> {_ in rhs() }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==>><O: Publisher>(_ lhs: O?, _ rhs: @escaping (O.Output) -> Void) where O.Output: Equatable {
    lhs?.removeDuplicates().skipFailure().receive(on: RunLoop.main).subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: rhs))
}
