//
//  Rx++.swift
//  MusicImport
//
//  Created by Данил Войдилов on 21.06.2019.
//  Copyright © 2019 Данил Войдилов. All rights reserved.
//

import Foundation
import Combine
import VDKit

@available(iOS 13.0, macOS 10.15, *)
public protocol PublishersMergerType: ArrayInitable {
	associatedtype Output
	associatedtype Failure: Error
}
@available(iOS 13.0, macOS 10.15, *)
public enum PublishersMerger<Output, Failure: Error>: PublishersMergerType {
	public static func create(from: [AnyPublisher<Output, Failure>]) -> AnyPublisher<Output, Failure> {
		Publishers.MergeMany(from).eraseToAnyPublisher()
	}
}

@available(iOS 13.0, macOS 10.15, *)
public typealias MergeBuilder<Output, Failure: Error> = ComposeBuilder<PublishersMerger<Output, Failure>>

@available(iOS 13.0, macOS 10.15, *)
extension ComposeBuilder where C: PublishersMergerType, C.Item == AnyPublisher<C.Output, C.Failure> {
	
	public static func buildExpression(_ expression: C.Output) -> AnyPublisher<C.Output, C.Failure> {
		Just(expression).setFailureType(to: C.Failure.self).eraseToAnyPublisher()
	}
	
	public static func buildExpression(_ expression: [C.Output]) -> AnyPublisher<C.Output, C.Failure> {
		Publishers.Sequence(sequence: expression).eraseToAnyPublisher()
	}
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<C.Output, C.Failure> where P.Output == C.Output, P.Failure == C.Failure {
		expression.eraseToAnyPublisher()
	}
	
}

extension ComposeBuilder where C: PublishersMergerType, C.Item == AnyPublisher<C.Output, C.Failure>, C.Failure == Error {
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<C.Output, C.Failure> where P.Output == C.Output {
		expression.simpleError().eraseToAnyPublisher()
	}
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<C.Output, C.Failure> where P.Output == C.Output, P.Failure == Error {
		expression.eraseToAnyPublisher()
	}
}

extension ComposeBuilder where C: PublishersMergerType, C.Item == AnyPublisher<C.Output, C.Failure>, C.Failure == Never {
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<C.Output, C.Failure> where P.Output == C.Output {
		expression.skipFailure().eraseToAnyPublisher()
	}
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<C.Output, C.Failure> where P.Output == C.Output, P.Failure == Never {
		expression.eraseToAnyPublisher()
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension Publishers {
	public static func merge<Output, Failure: Error>(@MergeBuilder<Output, Failure> _ build: () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
		build()
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {

	public func skipFailure() -> Publishers.Catch<Self, Empty<Output, Never>> {
		self.catch { _ in Empty(completeImmediately: false) }
	}

	public func `catch`(_ just: Output) -> Publishers.Catch<Self, Just<Output>> {
		self.catch { _ in Just(just) }
	}

	public func simpleError() -> Publishers.MapError<Self, Error> {
		mapError { $0 }
	}

	public func map<B: AnyObject, T>(_ method:  @escaping (B) -> (Output) -> T, on object: B) -> Publishers.CompactMap<Self, T> {
		compactMap {[weak object] in
			guard let obj = object else { return nil }
			return method(obj)($0)
		}
	}

	public func interval(_ period: TimeInterval, runLoop: RunLoop = .main) -> AnyPublisher<Output, Never> {
		skipFailure().zip(
			Timer.TimerPublisher(interval: period, runLoop: runLoop, mode: .default).autoconnect().prepend(Date())
		).map { $0.0 }
		.eraseToAnyPublisher()
	}

	public func withLast(initial value: Output) -> Publishers.Scan<Self, (previous: Output, current: Output)> {
		scan((value, value)) { ($0.1, $1) }
	}

	public func withLast() -> Publishers.WithLast<Self> {
		scan((nil, nil)) { ($0.1, $1) }.map { ($0.0, $0.1!) }
	}

	public func value<T>(_ value: T) -> Publishers.Map<Self, T> {
		map { _ in value }
	}
	
	@inlinable
	public func any() -> AnyPublisher<Output, Failure> {
		eraseToAnyPublisher()
	}

	public func asResult() -> AnyPublisher<Result<Output, Failure>, Never> {
		map { .success($0) }
			.catch { Just(.failure($0)) }
			.eraseToAnyPublisher()
	}

	public func append(_ values: Output...) -> Publishers.Concatenate<Self, Publishers.Sequence<[Output], Failure>> {
		append(Publishers.Sequence(sequence: values))
	}

	public func andIsSame<T: Equatable>(_ keyPath: KeyPath<Output, T>) -> Publishers.Map<Publishers.WithLast<Self>, (Self.Output, Bool)> {
		withLast().map {
			($0.1, $0.0?[keyPath: keyPath] == $0.1[keyPath: keyPath])
		}
	}

	public func onValue(_ action: @escaping (Output) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveOutput: action)
	}

	public func onFailure(_ action: @escaping (Error) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .failure(let error) = $0 {
				action(error)
			}
		})
	}

	public func onFinished(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .finished = $0 {
				action()
			}
		})
	}

	public func onSubscribe(_ action: @escaping (Subscription) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveSubscription: action)
	}

	public func onCancel(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCancel: action)
	}

	public func onRequest(_ action: @escaping (Subscribers.Demand) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveRequest: action)
	}

	public func `guard`(_ condition: @escaping (Output) throws -> Bool) -> Publishers.TryMap<Self, Output> {
		tryMap {
			guard try condition($0) else {
				throw CombineError.condition
			}
			return $0
		}
	}

	public func flat<P: Publisher>(_ transform: @escaping (Output) -> P) -> AnyPublisher<P.Output, Failure> {
		if #available(iOS 14.0, *) {
			return flatMap { transform($0).skipFailure() }.eraseToAnyPublisher()
		} else {
			return Publishers.FlatMapiOS13(source: self, map: transform).eraseToAnyPublisher()
		}
	}

}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: OptionalProtocol {

	public func isNil() -> Publishers.Map<Self, Bool> {
		map { $0.asOptional() == nil }
	}

	public func skipNil() -> Publishers.SkipNil<Self> {
		Publishers.SkipNil(source: self)
	}

	public func or(_ value: Output.Wrapped) -> Publishers.Map<Self, Output.Wrapped> {
		map { $0.asOptional() ?? value }
	}

}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output == Bool {

	public func toggle() -> Publishers.Map<Self, Bool> {
		map { !$0 }
	}

}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: Collection {
	public func skipEqualSize() -> Publishers.RemoveDuplicates<Self> {
		removeDuplicates { $0.count == $1.count }
	}
	public var nilIfEmpty: Publishers.Map<Self, Output?> { map { $0.isEmpty ? nil : $0 } }
	public var isEmpty: Publishers.Map<Self, Bool> { map { $0.isEmpty } }
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: OptionalProtocol {
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: OptionalProtocol, Output.Wrapped: Collection {
	public var isNilOrEmpty: Publishers.Map<Self, Bool> { map { $0.asOptional()?.isEmpty != false } }
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: Equatable {
	@inlinable
	public func skipEqual() -> Publishers.RemoveDuplicates<Self> { removeDuplicates() }
}


@available(iOS 13.0, macOS 10.15, *)
extension Publishers {

	public typealias WithLast<P: Publisher> = Map<Scan<P, (P.Output?, P.Output?)>, (P.Output?, P.Output)>

	public struct SkipNil<P: Publisher>: Publisher where P.Output: OptionalProtocol {
		public typealias Output = P.Output.Wrapped
		public typealias Failure = P.Failure
		public let source: P

		public func receive<S: Subscriber>(subscriber: S) where P.Failure == S.Failure, P.Output.Wrapped == S.Input {
			source.map { $0.asOptional() }.receive(subscriber: subscriber.ignoreNil())
		}
		
	}

}

extension AnyPublisher {
	
	public static func just(_ value: Output) -> AnyPublisher {
		Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
	}
	
	public static func never() -> AnyPublisher {
		Empty(completeImmediately: false).eraseToAnyPublisher()
	}
	
	public static func from(_ values: Output...) -> AnyPublisher {
		from(values)
	}
	
	public static func from<S: Sequence>(_ values: S) -> AnyPublisher where S.Element == Output {
		Publishers.Sequence(sequence: values).eraseToAnyPublisher()
	}
	
	public static func error(_ error: Failure) -> AnyPublisher {
		Result.Publisher(.failure(error)).eraseToAnyPublisher()
	}
	
	public static func empty() -> AnyPublisher {
		Empty(completeImmediately: true).eraseToAnyPublisher()
	}
	
}

extension Publisher {
	
	@discardableResult
	public func bind<S: Subscriber>(_ subscriber: S) -> Cancellable where S.Input == Output, S.Failure == Failure {
		let cancels = Cancels()
		subscribe(
			CancellableSubscriber<S>(subscriber: subscriber) {[weak cancels] cancel in
				cancels?.list.append(cancel)
			} remove: {[weak cancels] in
				cancels?.removeAll()
			} isCancel: {[weak cancels] in
				cancels?.isCancelled ?? false
			}
		)
		return cancels
	}
	
	@discardableResult
	public func bind(receiveValue: ((Output) -> Subscribers.Demand)? = nil, receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil) -> Cancellable {
		bind(
			AnySubscriber(
				receiveSubscription: {
					$0.request(.unlimited)
				},
				receiveValue: receiveValue,
				receiveCompletion: receiveCompletion
			)
		)
	}
	
	@discardableResult
	public func bind(receiveValue: @escaping (Output) -> Void) -> Cancellable {
		bind(
			AnySubscriber(
				receiveSubscription: {
					$0.request(.unlimited)
				},
				receiveValue: {
					receiveValue($0)
					return .unlimited
				},
				receiveCompletion: nil
			)
		)
	}
	
	public func subscribe(receiveValue: ((Output) -> Subscribers.Demand)? = nil, receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil) {
		subscribe(
			AnySubscriber(
				receiveSubscription: {
					$0.request(.unlimited)
				},
				receiveValue: receiveValue,
				receiveCompletion: receiveCompletion
			)
		)
	}
	
	public func subscribe(receiveValue: @escaping (Output) -> Void) {
		subscribe(
			AnySubscriber(
				receiveSubscription: {
					$0.request(.unlimited)
				},
				receiveValue: {
					receiveValue($0)
					return .unlimited
				},
				receiveCompletion: nil
			)
		)
	}
	
	public func sink<S: Subscriber>(_ subscriber: S) -> AnyCancellable where S.Failure == Failure, S.Input == Output {
		AnyCancellable(bind(subscriber))
	}
}

private struct CancellableSubscriber<S: Subscriber>: Subscriber {
	typealias Input = S.Input
	typealias Failure = S.Failure
	var combineIdentifier: CombineIdentifier { subscriber.combineIdentifier }
	let subscriber: S
	let insertCancel: (@escaping () -> Void) -> Void
	let remove: () -> Void
	let isCancel: () -> Bool
	
	func receive(subscription: Subscription) {
		guard !isCancel() else { return }
		insertCancel(subscription.cancel)
		subscriber.receive(subscription: subscription)
	}
	
	func receive(_ input: S.Input) -> Subscribers.Demand {
		guard !isCancel() else { return .none }
		return subscriber.receive(input)
	}
	
	func receive(completion: Subscribers.Completion<Failure>) {
		guard !isCancel() else { return }
		subscriber.receive(completion: completion)
		remove()
	}
}

private final class Cancels: Cancellable {
	var list: [() -> Void] = []
	var isCancelled = false
	
	func cancel() {
		isCancelled = true
		list.forEach { $0() }
		list = []
	}
	
	func removeAll() {
		list = []
	}
}
