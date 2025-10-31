import Foundation
import Combine

public final class ReplaySubject<Output, Failure: Error>: Subject {

	private var buffer: [Output] = []
	private let bufferSize: Int
	private var subscriptions = [UUID: ReplaySubjectSubscription<Output, Failure>]()
	private var completion: Subscribers.Completion<Failure>?
	private let lock = Lock()
	
	public init(_ bufferSize: Int = 0) {
		self.bufferSize = bufferSize
	}

	/// Provides this Subject an opportunity to establish demand for any new upstream subscriptions
	public func send(subscription: Subscription) {
		subscription.request(.unlimited)
	}

	/// Sends a value to the subscriber.
	public func send(_ value: Output) {
        lock.withLock {
            buffer.append(value)
            buffer = buffer.suffix(bufferSize)
            return subscriptions.values
        }
        .forEach { $0.receive(value) }
	}

	/// Sends a completion signal to the subscriber.
	public func send(completion: Subscribers.Completion<Failure>) {
        lock.withLock {
            self.completion = completion
            let results = subscriptions.values
            subscriptions = [:]
            return results
        }
        .forEach { $0.receive(completion: completion) }
	}

	/// This function is called to attach the specified `Subscriber` to the`Publisher
	public func receive<Downstream: Subscriber>(subscriber: Downstream) where Downstream.Failure == Failure, Downstream.Input == Output {
        let id = UUID()
        let subscription = ReplaySubjectSubscription<Output, Failure>(AnySubscriber(subscriber)) {[weak self] in
            self?.cancel(id: id)
        }
        let (buffer, completion) = lock.withLock { () -> ([Output], Subscribers.Completion<Failure>?) in
            if completion == nil {
                subscriptions[id] = subscription
            }
            return (self.buffer, self.completion)
        }
        subscriber.receive(subscription: subscription)
		subscription.replay(buffer, completion: completion)
	}

	private func cancel(id: UUID) {
        lock.withLock {
            subscriptions[id] = nil
        }
	}
}

public final class ReplaySubjectSubscription<Output, Failure: Error>: Subscription {

	private let downstream: AnySubscriber<Output, Failure>
	private var isCompleted = false
	private var demand: Subscribers.Demand = .none
	private let finish: () -> Void
	
	public init(_ downstream: AnySubscriber<Output, Failure>, cancel: @escaping () -> Void) {
		self.downstream = downstream
		finish = cancel
	}
	
	// Tells a publisher that it may send more values to the subscriber.
	public func request(_ newDemand: Subscribers.Demand) {
		demand += newDemand
	}
	
	public func cancel() {
		isCompleted = true
		finish()
	}
	
	public func receive(_ value: Output) {
		guard !isCompleted, demand > 0 else { return }

		demand += downstream.receive(value) - 1
	}
	
	public func receive(completion: Subscribers.Completion<Failure>) {
		guard !isCompleted else { return }
		isCompleted = true
		downstream.receive(completion: completion)
	}
	
	public func replay(_ values: [Output], completion: Subscribers.Completion<Failure>?) {
		guard !isCompleted else { return }
		values.forEach { value in receive(value) }
		if let completion = completion { receive(completion: completion) }
	}
}

extension Publisher {

	public func share(replay bufferSize: Int = 0) -> some Publisher<Output, Failure> {
		multicast(subject: ReplaySubject(bufferSize)).autoconnect()
	}
}
