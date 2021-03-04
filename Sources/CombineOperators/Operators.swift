//
//  CombineOperators.swift
//
//  Created by Данил Войдилов on 19.07.2018.
//

import Foundation
import VDKit
import Combine

precedencegroup CombinePrecedence {
	associativity: left
	higherThan: FunctionArrowPrecedence
	lowerThan: TernaryPrecedence
}

infix operator =>  : CombinePrecedence
infix operator ==> : CombinePrecedence

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == T.Failure {
	rhs.flatMap { lhs?.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Error {
	rhs.flatMap { lhs?.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == T.Failure, O.Failure == Never {
	rhs.flatMap { lhs?.subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == Error {
	rhs.flatMap { lhs?.simpleError().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, O.Failure == Never {
	rhs.flatMap { lhs?.skipFailure().subscribe($0) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, T.Failure == Never {
	rhs.flatMap { lhs?.subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output, T.Failure == Never, O.Failure == Error {
	rhs.flatMap { lhs?.subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == T.Failure {
	rhs.flatMap { lhs?.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Error {
	rhs.flatMap { lhs?.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == T.Failure, O.Failure == Never {
	rhs.flatMap { lhs?.subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == Error {
	rhs.flatMap { lhs?.simpleError().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, O: Subject>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, O.Failure == Never {
	rhs.flatMap { lhs?.skipFailure().subscribe($0) } ?? AnyCancellable()
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><O: Publisher>(_ lhs: O?, _ rhs: @escaping (O.Output) -> Void) {
	lhs?.subscribe(AnySubscriber.create(rhs))
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><O: Publisher>(_ lhs: O?, _ rhs: @escaping @autoclosure () -> Void) {
	lhs => {_ in rhs() }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==><O: Publisher>(_ lhs: O?, _ rhs: @escaping @autoclosure () -> Void) where O.Output: Equatable {
	lhs ==> {_ in rhs() }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><O: Publisher>(_ lhs: O?, _ rhs: [(O.Output) -> ()]) {
	rhs.forEach { lhs?.subscribe(AnySubscriber.create($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==><T: Publisher, O: Subscriber>(_ lhs: T?, _ rhs: O?) where O.Input == T.Output {
	rhs.map { lhs?.skipFailure().receive(on: DispatchQueue.main).subscribe(Subscribers.Garantie($0)) }
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func ==><O: Publisher>(_ lhs: O?, _ rhs: @escaping (O.Output) -> Void) {
	lhs?.skipFailure().receive(on: DispatchQueue.main).subscribe(AnySubscriber.create(rhs))
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =>(_ lhs: Cancellable?, _ rhs: inout Set<AnyCancellable>) {
	lhs?.store(in: &rhs)
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><R: RangeReplaceableCollection>(_ lhs: Cancellable?, _ rhs: inout R) where R.Element == AnyCancellable {
	lhs?.store(in: &rhs)
}

@available(iOS 13.0, macOS 10.15, *)
public func =>(_ lhs: Cancellable?, _ rhs: CancellableBagType) {
	lhs?.store(in: rhs)
}

@available(iOS 13.0, macOS 10.15, *)
@inlinable
public func =><T: Publisher, S: Scheduler>(_ lhs: T?, _ rhs: S) -> Publishers.SubscribeOn<T, S>? {
	lhs?.subscribe(on: rhs)
}

@available(iOS 13.0, macOS 10.15, *)
public prefix func !<O: Publisher>(_ rhs: O) -> Publishers.Map<O, Bool> where O.Output == Bool {
	rhs.map { !$0 }
}

@available(iOS 13.0, macOS 10.15, *)
public prefix func !<O: Subscriber>(_ rhs: O) -> Subscribers.MapSubscriber<O, Bool> where O.Input == Bool {
	rhs.mapSubscriber { !$0 }
}

@available(iOS 13.0, macOS 10.15, *)
public func +<T: Publisher, O: Publisher>(_ lhs: T, _ rhs: O) -> Publishers.Merge<T, O> where O.Output == T.Output, O.Failure == T.Failure {
	lhs.merge(with: rhs)
}

@available(iOS 13.0, macOS 10.15, *)
public func +<T: Subscriber, O: Subscriber>(_ lhs: T, _ rhs: O) -> AnySubscriber<O.Input, O.Failure> where O.Input == T.Input, O.Failure == T.Failure {
	AnySubscriber(
		receiveSubscription: {
			lhs.receive(subscription: $0)
			rhs.receive(subscription: $0)
		},
		receiveValue: {
			min(lhs.receive($0), rhs.receive($0))
		},
		receiveCompletion: {
			lhs.receive(completion: $0)
			rhs.receive(completion: $0)
		}
	)
}

@available(iOS 13.0, macOS 10.15, *)
public func +(_ lhs: Cancellable, _ rhs: Cancellable) -> Cancellable {
	AnyCancellable(lhs, rhs)
}

@available(iOS 13.0, macOS 10.15, *)
public func ?? <O: Publisher>(_ lhs: O, _ rhs: @escaping @autoclosure () -> O.Output.Wrapped) -> Publishers.Map<O, O.Output.Wrapped> where O.Output: OptionalProtocol {
	lhs.map { $0.asOptional() ?? rhs() }
}

@available(iOS 13.0, macOS 10.15, *)
public func &<T1: Publisher, T2: Publisher>(_ lhs: T1, _ rhs: T2) -> Publishers.CombineLatest<T1, T2> where T1.Failure == T2.Failure { lhs.combineLatest(rhs) }

@available(iOS 13.0, macOS 10.15, *)
extension AnySubscriber {
	@inlinable
	static func create(_ receive: @escaping (Input) -> Void) -> AnySubscriber {
		AnySubscriber(
			receiveSubscription: {
				$0.request(.unlimited)
		},
		receiveValue: {
			receive($0)
			return .unlimited
		})
	}
}
