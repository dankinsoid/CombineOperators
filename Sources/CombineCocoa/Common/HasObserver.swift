import Combine
import CombineOperators
import Foundation

/// Subject wrapper that tracks active subscriber count.
///
/// Used internally to enable lazy resource management (e.g., start/stop event listeners
/// only when observers are present).
final class HasObserver<Output>: Subject {
	typealias Failure = Error
	private let subject = PassthroughSubject<Output, Error>()
	var hasObservers: Bool { lock.withLock { subscriptionsCount > 0 } }
	private var subscriptionsCount = 0
	private let lock = Lock()

	func receive<S: Subscriber>(subscriber: S) where Error == S.Failure, Output == S.Input {
		subject.receive(subscriber: subscriber)
	}

	func send(_ value: Output) {
		subject.send(value)
	}

	func send(completion: Subscribers.Completion<Error>) {
		subject.send(completion: completion)
	}

	func send(subscription: Subscription) {
		subscriptionsCount += 1
		subject.send(subscription: SubscriptionHas(subscription: subscription, onCancelled: { [weak self] in
			self?.lock.withLock { self?.subscriptionsCount -= 1 }
		}))
	}

	private struct SubscriptionHas: Subscription {
		var combineIdentifier: CombineIdentifier { subscription.combineIdentifier }
		let subscription: Subscription
		let onCancelled: () -> Void

		func request(_ demand: Subscribers.Demand) {
			subscription.request(demand)
		}

		func cancel() {
			subscription.cancel()
			onCancelled()
		}
	}
}
