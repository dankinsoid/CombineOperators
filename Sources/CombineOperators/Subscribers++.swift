//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import VDKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Subscriber {
	
	public func mapSubscriber<T>(_ map: @escaping (T) -> Input) -> Subscribers.MapSubscriber<Self, T> {
		Subscribers.MapSubscriber(source: self, map: map)
	}
	
	public func ignoreFailure() -> Subscribers.Garantie<Self> {
		Subscribers.Garantie(self)
	}
	
	public func ignoreNil() -> Subscribers.IgnoreNil<Self> {
		Subscribers.IgnoreNil(source: self)
	}
	
	public func any() -> AnySubscriber<Input, Failure> {
		AnySubscriber(self)
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Subscribers {
	
	public struct Garantie<S: Subscriber>: Subscriber {
		public typealias Input = S.Input
		public typealias Failure = Never
		public var combineIdentifier: CombineIdentifier { source.combineIdentifier }
		public let source: S
		
		public init(_ source: S) {
			self.source = source
		}
		
		public func receive(subscription: Subscription) {
			source.receive(subscription: subscription)
		}
		
		public func receive(_ input: S.Input) -> Subscribers.Demand {
			source.receive(input)
		}
		
		public func receive(completion: Subscribers.Completion<Never>) {
			source.receive(completion: .finished)
		}
	}
	
	public struct MapSubscriber<S: Subscriber, Input>: Subscriber {
		public var combineIdentifier: CombineIdentifier { source.combineIdentifier }
		public let source: S
		public let map: (Input) -> S.Input
		
		public func receive(subscription: Subscription) {
			source.receive(subscription: subscription)
		}
		
		public func receive(_ input: Input) -> Subscribers.Demand {
			source.receive(map(input))
		}
		
		public func receive(completion: Subscribers.Completion<S.Failure>) {
			source.receive(completion: completion)
		}
	}
	
	public struct IgnoreNil<S: Subscriber>: Subscriber {
		public typealias Input = S.Input?
		public typealias Failure = S.Failure
		
		public var combineIdentifier: CombineIdentifier { source.combineIdentifier }
		public let source: S
		
		public func receive(subscription: Subscription) {
			source.receive(subscription: subscription)
		}
		
		public func receive(_ input: Input) -> Subscribers.Demand {
			input.map { source.receive($0) } ?? .unlimited
		}
		
		public func receive(completion: Subscribers.Completion<S.Failure>) {
			source.receive(completion: completion)
		}
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Subscribers.Completion {
	public func map<F: Error>(_ mapper: (Failure) -> F) -> Subscribers.Completion<F> {
		switch self {
		case .finished: 						return .finished
		case .failure(let failure): return .failure(mapper(failure))
		}
	}
}

extension Subject {
	public func asSubscriber() -> AnySubscriber<Output, Failure> {
		AnySubscriber {
			self.send(subscription: $0)
		} receiveValue: {
			self.send($0)
			return .unlimited
		} receiveCompletion: {
			self.send(completion: $0)
		}
	}
}
