import Combine
import Foundation
import os

public extension Publishers {

	/// Publisher created from a closure that receives a subscriber.
	///
	/// Provides manual control over publisher lifecycle.
	///
	/// ```swift
	/// let publisher = Publishers.Create<Int, Never> { subscriber in
	///     subscriber.receive(1)
	///     subscriber.receive(2)
	///     subscriber.receive(completion: .finished)
	///     return AnyCancellable {}
	/// }
	/// ```
	struct Create<Output, Failure: Swift.Error>: Publisher {

		private let closure: (AnySubscriber<Output, Failure>) -> Cancellable

		public init(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) {
			self.closure = closure
		}

		public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
			let subscription = Subscriptions.Anonymous(subscriber: subscriber, closure: closure)
			subscriber.receive(subscription: subscription)
		}
	}
}

extension Subscriptions {

	final class Anonymous<SubscriberType: Subscriber, Output, Failure>: Subscription where
		SubscriberType.Input == Output,
		Failure == SubscriberType.Failure
	{

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

public extension AnyPublisher {

	/// Creates a publisher from a closure with full control over emissions.
	///
	/// ```swift
	/// AnyPublisher<String, Never>.create { subscriber in
	///     subscriber.receive("Hello")
	///     subscriber.receive(completion: .finished)
	///     return AnyCancellable { print("Cancelled") }
	/// }
	/// ```
	static func create(_ closure: @escaping (AnySubscriber<Output, Failure>) -> Cancellable) -> AnyPublisher {
		Publishers.Create<Output, Failure>(closure).eraseToAnyPublisher()
	}
}
