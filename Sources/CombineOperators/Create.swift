//
//  File.swift
//  
//
//  Created by Данил Войдилов on 27.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Publishers {
	
	public final class Create<Output, Failure: Swift.Error>: Publisher {
		private var closure: (AnySubscriber<Output, Failure>) -> Cancellable
		private let lock = NSRecursiveLock()
		private var subscriptions: [CombineIdentifier: Any] = [:]
		
		public init(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
			self.closure = closure
		}
		
		public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
			let subscription = Subscriptions.Anonymous(subscriber: subscriber, closure: closure) {[weak self] in
				self?.disassociate($0)
			}
			subscriber.receive(subscription: subscription)
			lock.lock()
			subscriptions[subscription.combineIdentifier] = subscription
			lock.unlock()
		}
		
		private func disassociate(_ id: CombineIdentifier) {
			lock.lock()
			subscriptions[id] = nil
			lock.unlock()
		}
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension Subscriptions {
	
	final class Anonymous<SubscriberType: Subscriber, Output, Failure>: Subscription where SubscriberType.Input == Output, Failure == SubscriberType.Failure {
		
		private var subscriber: SubscriberType?
		private var cancellable: Cancellable?
		private var disassociate: (CombineIdentifier) -> Void
		private let lock = NSRecursiveLock()
		private var closure: (AnySubscriber<Output, Failure>) -> Cancellable
		
		init(subscriber: SubscriberType, closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable, disassociate: @escaping (CombineIdentifier) -> Void) {
			self.subscriber = subscriber
			self.closure = closure
			self.disassociate = disassociate
		}
		
		func request(_ demand: Subscribers.Demand) {
			guard demand > 0, cancellable == nil else { return }
			lock.lock()
			if let subscriber = subscriber {
				cancellable = closure(AnySubscriber(AnonymousSubscriber(subscriber: subscriber)))
			}
			lock.unlock()
		}
		
		func cancel() {
			lock.lock()
			cancellable?.cancel()
			cancellable = nil
			self.subscriber = nil
			disassociate(combineIdentifier)
			lock.unlock()
		}
		
		deinit {
			cancellable?.cancel()
		}
		
		private struct AnonymousSubscriber: Subscriber {
			var combineIdentifier: CombineIdentifier { subscriber.combineIdentifier }
			var subscriber: SubscriberType
			
			func receive(subscription: Subscription) {}
			
			func receive(_ input: SubscriberType.Input) -> Subscribers.Demand {
				subscriber.receive(input)
			}
			
			func receive(completion: Subscribers.Completion<SubscriberType.Failure>) {
				subscriber.receive(completion: completion)
			}
			
		}
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension AnyPublisher {
	
	public static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) -> AnyPublisher {
		Publishers.Create<Output, Failure>(closure).eraseToAnyPublisher()
	}
	
}
