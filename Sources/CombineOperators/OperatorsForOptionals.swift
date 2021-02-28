//
//  RxOperatorsForOptionals.swift
//  RxOperators
//
//  Created by Daniil on 16.08.2019.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == T.Failure {
	rhs.flatMap { lhs?.map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	rhs.flatMap { lhs?.map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	rhs.flatMap { lhs?.map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == Error {
	rhs.flatMap { lhs?.simpleError().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, O.Failure == Never {
	rhs.flatMap { lhs?.skipFailure().map { $0 }.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, T.Failure == Never {
	rhs.flatMap { lhs?.map { $0 }.subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output?, T.Failure == Never, O.Failure == Error {
	rhs.flatMap { lhs?.map { $0 }.subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output?, O.Failure == T.Failure {
	rhs.flatMap { lhs?.map { $0 }.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Error {
	rhs.flatMap { lhs?.map { $0 }.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output?, O.Failure == T.Failure, O.Failure == Never {
	rhs.flatMap { lhs?.map { $0 }.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output?, O.Failure == Error {
	rhs.flatMap { lhs?.map { $0 }.simpleError().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output?, O.Failure == Never {
	rhs.flatMap { lhs?.map { $0 }.skipFailure().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output? {
	rhs.map { lhs?.map { $0 }.skipFailure().subscribe(on: DispatchQueue.main).subscribe(Subscribers.Garantie($0)) }
}


@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == T.Failure {
	rhs.flatMap { lhs?.skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == T.Failure, O.Failure == Error {
	rhs.flatMap { lhs?.skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == T.Failure, O.Failure == Never {
	rhs.flatMap { lhs?.skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == Error {
	rhs.flatMap { lhs?.simpleError().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, O.Failure == Never {
	rhs.flatMap { lhs?.skipFailure().skipNil().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, T.Failure == Never {
	rhs.flatMap { lhs?.skipNil().subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output, T.Failure == Never, O.Failure == Error {
	rhs.flatMap { lhs?.skipNil().subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output? == T.Output, O.Failure == T.Failure {
	rhs.flatMap { lhs?.skipNil().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output? == T.Output, O.Failure == T.Failure, O.Failure == Error {
	rhs.flatMap { lhs?.skipNil().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output? == T.Output, O.Failure == T.Failure, O.Failure == Never {
	rhs.flatMap { lhs?.skipNil().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output? == T.Output, O.Failure == Error {
	rhs.flatMap { lhs?.skipNil().simpleError().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output? == T.Output, O.Failure == Never {
	rhs.flatMap { lhs?.skipNil().skipFailure().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input? == T.Output {
	rhs.map { lhs?.skipNil().skipFailure().subscribe(on: DispatchQueue.main).subscribe(Subscribers.Garantie($0)) }
}
