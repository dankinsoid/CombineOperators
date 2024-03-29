import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
final class HasObserver<Output>: Subject {
	typealias Failure = Error
	private let subject = PassthroughSubject<Output, Error>()
	var hasObservers: Bool { lock.performLocked { subscriptionsCount > 0 } }
	private var subscriptionsCount = 0
	private let lock = NSRecursiveLock()
	
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
		subject.send(subscription: SubscriptionHas(subscription: subscription, onCancelled: {[weak self] in
			self?.lock.performLocked { self?.subscriptionsCount -= 1 }
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
