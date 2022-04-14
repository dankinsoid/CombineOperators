//
//  File.swift
//  
//
//  Created by Данил Войдилов on 03.03.2021.
//

import Foundation
import Combine

@dynamicMemberLookup
@propertyWrapper
public struct ValueSubject<Output> {
	public typealias Failure = Never
	public var wrappedValue: Output {
		get { projectedValue.value }
		nonmutating set { projectedValue.value = newValue }
	}
	public let projectedValue: CurrentValueSubject<Output, Never>
	
	public init(wrappedValue: Output) {
		projectedValue = CurrentValueSubject(wrappedValue)
	}
	public subscript <R>(dynamicMember keyPath: KeyPath<Output, R>) -> ObservableChain<R, Failure> {
		ObservableChain<R, Failure>(observable: projectedValue.map { $0[keyPath: keyPath] }.any())
	}
}
@dynamicMemberLookup
public struct ObservableChain<Output, Failure: Error> {
	let observable: AnyPublisher<Output, Failure>
	var cancelables: [AnyCancellable] = []
	
	public subscript <R>(dynamicMember keyPath: KeyPath<Output, R>) -> ObservableChain<R, Failure> {
		ObservableChain<R, Failure>(observable: self.map { $0[keyPath: keyPath] }.any() )
	}
}

extension ObservableChain: Publisher {
	
	public func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
		observable.receive(subscriber: subscriber)
	}
	
	public typealias Output = Output
	
	public typealias Failure = Failure
	
}


extension CurrentValueSubject: Subscriber {
	public func receive(completion: Subscribers.Completion<Failure>) {
		
	}
	
	public func receive(_ input: Output) -> Subscribers.Demand {
		value = input
		return .unlimited
	}
	
	public func receive(subscription: Subscription) {
		subscription.request(.unlimited)
	}
	
	public typealias Input = Output
}



extension ValueSubject: Subscriber {
	public var combineIdentifier: CombineIdentifier {
		projectedValue.combineIdentifier
	}
	
	public func receive(completion: Subscribers.Completion<Failure>) {
		
	}
	
	public func receive(_ input: Output) -> Subscribers.Demand {
		projectedValue.value = input
		return .unlimited
	}
	
	public func receive(subscription: Subscription) {
		subscription.request(.unlimited)
	}
	
	public typealias Input = Output
}

extension ValueSubject: Publisher {
	public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
		projectedValue.receive(subscriber: subscriber)
	}
	
	
}

