//
//  File.swift
//  
//
//  Created by Данил Войдилов on 25.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Publishers {
	
	struct FlatMapiOS13<Source: Publisher, Mapped: Publisher>: Publisher {
		typealias Output = Mapped.Output
		typealias Failure = Source.Failure
		let source: Source
		let map: (Source.Output) -> Mapped
		
		func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
			source.receive(subscriber: FlatSubscriber(target: subscriber, map: map))
		}
		
		private final class FlatSubscriber<S: Subscriber>: Subscriber where S.Input == Mapped.Output {
			typealias Input = Source.Output
			typealias Failure = Source.Failure
			var combineIdentifier: CombineIdentifier { target.combineIdentifier }
			let target: S
			let map: (Source.Output) -> Mapped
			private var completions: [Cancellable] = []
			
			init(target: S, map: @escaping (Source.Output) -> Mapped) {
				self.target = target
				self.map = map
			}
			
			func receive(subscription: Subscription) {
				target.receive(subscription: subscription)
			}
			
			func receive(_ input: Source.Output) -> Subscribers.Demand {
				completions.append(map(input).sink(receiveCompletion: {_ in }, receiveValue: { _ = self.target.receive($0) }))
				return .unlimited
			}
			
			func receive(completion: Subscribers.Completion<Source.Failure>) {
				target.receive(completion: .finished)
				completions.forEach {
					$0.cancel()
				}
				completions = []
			}
		}
	}
}
