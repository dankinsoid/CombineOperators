//
//  File.swift
//  
//
//  Created by Данил Войдилов on 01.03.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Publishers {
	
	public struct Enumerated<Source: Publisher>: Publisher {
		public typealias Failure = Source.Failure
		public typealias Output = EnumeratedSequence<[Source.Output]>.Element
		public let source: Source
		
		public init(_ source: Source) {
			self.source = source
		}
		
		public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
			source.receive(subscriber: EnumeratedSubscriber(subscriber))
		}
		
		private final class EnumeratedSubscriber<S: Subscriber>: Subscriber where Failure == S.Failure, Output == S.Input {
			typealias Input = Source.Output
			typealias Failure = Source.Failure
			let subscriber: S
			var combineIdentifier: CombineIdentifier { subscriber.combineIdentifier }
			private var index = 0
			private let lock = NSRecursiveLock()
			
			init(_ subscriber: S) {
				self.subscriber = subscriber
			}
			
			func receive(_ input: Source.Output) -> Subscribers.Demand {
				lock.lock()
				let offset = index
				lock.unlock()
				let result = subscriber.receive((offset: offset, element: input))
				lock.lock()
				index += 1
				lock.unlock()
				return result
			}
			
			func receive(subscription: Subscription) {
				subscriber.receive(subscription: subscription)
			}
			
			func receive(completion: Subscribers.Completion<Source.Failure>) {
				subscriber.receive(completion: completion)
				lock.lock()
				index = 0
				lock.unlock()
			}
		}
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	
	public func enumerated() -> Publishers.Enumerated<Self> {
		Publishers.Enumerated(self)
	}
	
}
