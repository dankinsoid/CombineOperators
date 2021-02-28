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
	
	public struct Create<Output, Failure: Swift.Error>: Publisher {
		private var closure: (AnySubscriber<Output, Failure>) -> Cancellable
		
		public init(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
			self.closure = closure
		}
		
		public func receive<S>(subscriber: S) where S : Subscriber, Create.Failure == S.Failure, Create.Output == S.Input {
			let subscription = Subscriptions.Anonymous(subscriber: subscriber)
			subscriber.receive(subscription: subscription)
			subscription.start(closure)
		}
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Subscriptions {
	
	final class Anonymous<SubscriberType: Subscriber, Output, Failure>: Subscription where SubscriberType.Input == Output, Failure == SubscriberType.Failure {
		
		private var subscriber: SubscriberType?
		private var cancellable: Cancellable?
		
		init(subscriber: SubscriberType) {
			self.subscriber = subscriber
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
		}
		
		deinit {
			cancellable?.cancel()
			print("deinit")
		}
		
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension AnyPublisher {
	
	public static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) -> AnyPublisher {
		Publishers.Create<Output, Failure>(closure).eraseToAnyPublisher()
	}
	
}
