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
		
		public func receive<S>(subscriber: S) where S : Subscriber, Create.Failure == S.Failure, Create.Output == S.Input {
			let subscription = Subscriptions.Anonymous(subscriber: subscriber) {[weak self] in
				self?.disassociate($0)
			}
			subscriber.receive(subscription: subscription)
			subscription.start(closure)
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
		
		init(subscriber: SubscriberType, disassociate: @escaping (CombineIdentifier) -> Void) {
			self.subscriber = subscriber
			self.disassociate = disassociate
		}
		
		func start(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
			if let subscriber = subscriber {
				cancellable = closure(AnySubscriber(subscriber))
			}
		}
		
		func request(_ demand: Subscribers.Demand) {
			// Ignore demand for now
		}
		
		func cancel() {
			cancellable?.cancel()
			cancellable = nil
			self.subscriber = nil
			disassociate(combineIdentifier)
		}
		
		deinit {
			cancellable?.cancel()
		}
		
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension AnyPublisher {
	
	public static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) -> AnyPublisher {
		Publishers.Create<Output, Failure>(closure).eraseToAnyPublisher()
	}
	
}
