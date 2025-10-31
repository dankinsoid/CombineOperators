//
//  File.swift
//  
//
//  Created by Данил Войдилов on 27.02.2021.
//

import Foundation
import Combine
import os

extension Publishers {
	
	public struct Create<Output, Failure: Swift.Error>: Publisher {

		private let closure: (AnySubscriber<Output, Failure>) -> Cancellable
		
		public init(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
			self.closure = closure
		}

		public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
			let subscription = Subscriptions.Anonymous(subscriber: subscriber, closure: closure)
			subscriber.receive(subscription: subscription)
		}
	}
}

extension Subscriptions {
	
	final class Anonymous<SubscriberType: Subscriber, Output, Failure>: Subscription where
        SubscriberType.Input == Output,
        Failure == SubscriberType.Failure {
		
		private let subscriber: SubscriberType
		private var cancellable: Cancellable?
        private let lock = Lock()
		private var closure: (AnySubscriber<Output, Failure>) -> Cancellable
		
		init(subscriber: SubscriberType, closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
			self.subscriber = subscriber
			self.closure = closure
		}

		func request(_ demand: Subscribers.Demand) {
			guard demand > 0 else { return }
            let cancellable = closure(AnySubscriber(subscriber))
            lock.withLock {
                self.cancellable = cancellable
            }
		}

		func cancel() {
            let cancellable = lock.withLock { () -> Cancellable? in
                let cancellable = self.cancellable
                self.cancellable = nil
                return cancellable
            }
            cancellable?.cancel()
		}

		deinit {
			cancel()
		}
	}
}

extension AnyPublisher {

	public static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) -> AnyPublisher {
		Publishers.Create<Output, Failure>(closure).eraseToAnyPublisher()
	}
}
