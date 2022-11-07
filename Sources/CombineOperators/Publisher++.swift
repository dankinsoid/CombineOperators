//
//  Rx++.swift
//  MusicImport
//
//  Created by Данил Войдилов on 21.06.2019.
//  Copyright © 2019 Данил Войдилов. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
@resultBuilder
public struct MergeBuilder<Output, Failure: Error> {
	
	@inline(__always)
	public static func buildArray(_ components: [AnyPublisher<Output, Failure>]) -> AnyPublisher<Output, Failure> {
		Publishers.MergeMany(components).eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildEither<P: Publisher>(first component: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component.eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildEither<P: Publisher>(second component: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component.eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildOptional<P: Publisher>(_ component: P?) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component?.eraseToAnyPublisher() ?? Empty(completeImmediately: true).eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildLimitedAvailability<P: Publisher>(second component: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component.eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildBlock() -> AnyPublisher<Output, Failure> {
		Empty(completeImmediately: false).eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildBlock(_ components: AnyPublisher<Output, Failure>...) -> AnyPublisher<Output, Failure> {
		Publishers.MergeMany(components).eraseToAnyPublisher()
	}
	
	@inline(__always)
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		expression.eraseToAnyPublisher()
	}
	
	public static func buildExpression(_ expression: Output) -> AnyPublisher<Output, Failure> {
		Just(expression).setFailureType(to: Failure.self).eraseToAnyPublisher()
	}
	
	public static func buildExpression(_ expression: [Output]) -> AnyPublisher<Output, Failure> {
		Publishers.Sequence(sequence: expression).eraseToAnyPublisher()
	}
	
	public static func buildExpression<A: Collection>(_ expression: A) -> AnyPublisher<Output, Failure> where A.Element: Publisher, A.Element.Output == Output, A.Element.Failure == Failure {
		Publishers.MergeMany(expression).eraseToAnyPublisher()
	}
}

extension MergeBuilder where Failure == Error {
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output {
		expression.simpleError().eraseToAnyPublisher()
	}
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Error {
		expression.eraseToAnyPublisher()
	}
}

extension MergeBuilder where Failure == Never {
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output {
		expression.skipFailure().eraseToAnyPublisher()
	}
	
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Never {
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
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {

	public func isNil<T>() -> Publishers.Map<Self, Bool> where Output == T? {
		map { $0 == nil }
	}

	public func skipNil<T>() -> Publishers.SkipNil<Self, T> where Output == T? {
		Publishers.SkipNil(source: self)
	}

	public func or<T>(_ value: T) -> Publishers.Map<Self, T> where Output == T? {
		map { $0 ?? value }
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
extension Publisher {
	public func isNilOrEmpty<T: Collection>() -> Publishers.Map<Self, Bool> where Output == T? {
		map { $0?.isEmpty != false }
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: Equatable {
	@inlinable
	public func skipEqual() -> Publishers.RemoveDuplicates<Self> { removeDuplicates() }
}


@available(iOS 13.0, macOS 10.15, *)
extension Publishers {

	public typealias WithLast<P: Publisher> = Map<Scan<P, (P.Output?, P.Output?)>, (P.Output?, P.Output)>

	public struct SkipNil<P: Publisher, Output>: Publisher where P.Output == Output? {
		public typealias Failure = P.Failure
		public let source: P

		public func receive<S: Subscriber>(subscriber: S) where P.Failure == S.Failure, Output == S.Input {
			source.compactMap { $0 }.receive(subscriber: subscriber)
		}
	}
}

extension AnyPublisher {
	
	public static func just(_ value: Output) -> AnyPublisher {
		Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
	}
	
    public static var never: AnyPublisher {
		Empty(completeImmediately: false).eraseToAnyPublisher()
	}
	
	public static func from(_ values: Output...) -> AnyPublisher {
		from(values)
	}
	
	public static func from<S: Sequence>(_ values: S) -> AnyPublisher where S.Element == Output {
		Publishers.Sequence(sequence: values).eraseToAnyPublisher()
	}
	
	public static func failure(_ failure: Failure) -> AnyPublisher {
		Result.Publisher(.failure(failure)).eraseToAnyPublisher()
	}
	
    public static var empty: AnyPublisher {
		Empty(completeImmediately: true).eraseToAnyPublisher()
	}
}
