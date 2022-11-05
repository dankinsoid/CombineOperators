import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
public final class ReplaySubject<Output, Failure: Error>: Subject {
	private var buffer: [Output] = []
	private let bufferSize: Int
	private var subscriptions = [UUID: ReplaySubjectSubscription<Output, Failure>]()
	private var completion: Subscribers.Completion<Failure>?
	private let lock = NSRecursiveLock()
	
	public init(_ bufferSize: Int = 0) {
		self.bufferSize = bufferSize
	}
	
	/// Provides this Subject an opportunity to establish demand for any new upstream subscriptions
	public func send(subscription: Subscription) {
		lock.lock(); defer { lock.unlock() }
		subscription.request(.unlimited)
	}
	
	/// Sends a value to the subscriber.
	public func send(_ value: Output) {
		lock.lock(); defer { lock.unlock() }
		buffer.append(value)
		buffer = buffer.suffix(bufferSize)
		subscriptions.forEach { $0.value.receive(value) }
	}
	
	/// Sends a completion signal to the subscriber.
	public func send(completion: Subscribers.Completion<Failure>) {
		lock.lock(); defer { lock.unlock() }
		self.completion = completion
		subscriptions.forEach { subscription in subscription.value.receive(completion: completion) }
		subscriptions = [:]
	}
	
	/// This function is called to attach the specified `Subscriber` to the`Publisher
	public func receive<Downstream: Subscriber>(subscriber: Downstream) where Downstream.Failure == Failure, Downstream.Input == Output {
		lock.lock(); defer { lock.unlock() }
		let id = UUID()
		let subscription = ReplaySubjectSubscription<Output, Failure>(AnySubscriber(subscriber)) {[weak self] in
			self?.cancel(id: id)
		}
		subscriber.receive(subscription: subscription)
		if completion == nil {
			subscriptions[id] = subscription
		}
		subscription.replay(buffer, completion: completion)
	}
	
	private func cancel(id: UUID) {
		lock.lock(); defer { lock.unlock() }
		subscriptions[id] = nil
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
		
		demand += downstream.receive(value)
		demand -= 1
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

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	public func share(replay bufferSize: Int = 0) -> AnyPublisher<Output, Failure> {
		multicast(subject: ReplaySubject(bufferSize)).autoconnect().eraseToAnyPublisher()
	}
}
