//
//  File.swift
//  
//
//  Created by Данил Войдилов on 02.03.2021.
//

import Foundation
import Combine

extension Publisher {
	
	public func tryMap<T>(value: @escaping (Output) throws -> T, completion: @escaping (Subscribers.Completion<Failure>) throws -> T) -> AnyPublisher<T, Error> {
		Publishers.Create<T, Error> { subscriber in
			self.subscribe(
				AnySubscriber(
					receiveSubscription: {
						subscriber.receive(subscription: $0)
					}, receiveValue: {
						do {
							return try subscriber.receive(value($0)) + 1
						} catch {
							subscriber.receive(completion: .failure(error))
							return .none
						}
					}, receiveCompletion: {
						do {
							_ = try subscriber.receive(completion($0))
							subscriber.receive(completion: .finished)
						} catch {
							subscriber.receive(completion: .failure(error))
						}
					}
				)
			)
			return AnyCancellable()
		}.eraseToAnyPublisher()
	}
	
	public func map<T>(value: @escaping (Output) -> T, completion: @escaping (Subscribers.Completion<Failure>) -> T) -> AnyPublisher<T, Never> {
		Publishers.Create<T, Never> { subscriber in
			self.subscribe(
				AnySubscriber(
					receiveSubscription: {
						subscriber.receive(subscription: $0)
					}, receiveValue: {
						subscriber.receive(value($0)) + 1
					}, receiveCompletion: {
						_ = subscriber.receive(completion($0))
						subscriber.receive(completion: .finished)
					}
				)
			)
			return AnyCancellable()
		}.eraseToAnyPublisher()
	}
	
	public func mapCompletion(_ completion: @escaping (Subscribers.Completion<Failure>) -> Output) -> AnyPublisher<Output, Never> {
		map(value: { $0 }, completion: completion)
	}
}
