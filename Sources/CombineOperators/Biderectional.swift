//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import Combine

//infix operator <=>  : CombinePrecedence
//infix operator <==> : CombinePrecedence

//@available(iOS 13.0, macOS 10.15, *)
//fileprivate func bind<Output: Equatable>(_ lO: Publisher<Output>, _ rO: Publisher<Output>, _ lOb: AnySubscriber<Output>, _ rOb: AnySubscriber<Output>) -> Cancellable {
//	let subject = Publishers<Output>()
//	let d1 = lO.subscribe(subject)
//	let d2 = rO.subscribe(subject)
//	let d3 = subject.distinctUntilChanged().subscribe(rOb)
//	let d4 = subject.distinctUntilChanged().subscribe(lOb)
//	return AnyCancellable(d1, d2, d3, d4)
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//public func <=><T: Publisher & Subscriber, O: Publisher & Subscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	return bind(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//@discardableResult
//public func <=><T: Publisher & CancellableSubscriber, O: Publisher & Subscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	let result = bind(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//	l.insert(Cancellable: result)
//	return result
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//@discardableResult
//public func <=><T: Publisher & Subscriber, O: Publisher & CancellableSubscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	let result = bind(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//	r.insert(Cancellable: result)
//	return result
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//@discardableResult
//public func <=><T: Publisher & CancellableSubscriber, O: Publisher & CancellableSubscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	let result = bind(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//	r.insert(Cancellable: result)
//	l.insert(Cancellable: result)
//	return result
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//fileprivate func drive<Output: Equatable>(_ lO: Publisher<Output>, _ rO: Publisher<Output>, _ lOb: AnySubscriber<Output>, _ rOb: AnySubscriber<Output>) -> Cancellable {
//	let subject = PublishSubject<Output>()
//	let d1 = lO.subscribe(subject)
//	let d2 = rO.subscribe(subject)
//	let d3 = subject.distinctUntilChanged().asDriver().drive(rOb)
//	let d4 = subject.distinctUntilChanged().asDriver().drive(lOb)
//	return Cancellables.create(d1, d2, d3, d4)
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//public func <==><T: Publisher & Subscriber, O: Publisher & Subscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	return drive(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//@discardableResult
//public func <==><T: Publisher & CancellableSubscriber, O: Publisher & Subscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	let result = drive(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//	l.insert(Cancellable: result)
//	return result
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//@discardableResult
//public func <==><T: Publisher & Subscriber, O: Publisher & CancellableSubscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	let result = drive(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//	r.insert(Cancellable: result)
//	return result
//}
//
//@available(iOS 13.0, macOS 10.15, *)
//@discardableResult
//public func <==><T: Publisher & CancellableSubscriber, O: Publisher & CancellableSubscriber>(_ lhs: T?, _ rhs: O?) -> Cancellable where O.Output == T.Output, T.Output: Equatable {
//	guard let l = lhs, let r = rhs else { return Cancellables.create() }
//	let result = drive(l.asPublisher(), r.asPublisher(), l.asObserver(), r.asObserver())
//	r.insert(Cancellable: result)
//	l.insert(Cancellable: result)
//	return result
//}
