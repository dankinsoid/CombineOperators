import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == T.Failure, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == Error, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().simpleError().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == Never, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipFailure().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, T.Failure == Never, T.Output: Equatable {
    rhs.flatMap { lhs?.removeDuplicates().map { $0 }.setFailureType(to: O.Failure.self).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, T.Failure == Never, O.Failure == Error, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.setFailureType(to: O.Failure.self).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output == T.Output?, O.Failure == Error, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.simpleError().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output == T.Output?, O.Failure == Never, T.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().map { $0 }.skipFailure().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, T.Output: Equatable {
	rhs.map { lhs?.removeDuplicates().map { $0 }.skipFailure().setFailureType(to: O.Failure.self).receive(on: RunLoop.main).subscribe($0) }
}


@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == T.Failure, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == T.Failure, O.Failure == Error, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == T.Failure, O.Failure == Never, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == Error, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().simpleError().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == Never, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipFailure().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, T.Failure == Never, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().setFailureType(to: O.Failure.self).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, T.Failure == Never, O.Failure == Error, O.Input: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().setFailureType(to: O.Failure.self).subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output? == T.Output, O.Failure == T.Failure, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output? == T.Output, O.Failure == T.Failure, O.Failure == Error, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output? == T.Output, O.Failure == T.Failure, O.Failure == Never, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output? == T.Output, O.Failure == Error, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().simpleError().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> AnyCancellable where O.Output? == T.Output, O.Failure == Never, O.Output: Equatable {
	rhs.flatMap { lhs?.removeDuplicates().skipNil().skipFailure().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==>><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Input: Equatable {
	rhs.map { lhs?.removeDuplicates().skipNil().skipFailure().receive(on: RunLoop.main).setFailureType(to: O.Failure.self).subscribe($0) }
}
