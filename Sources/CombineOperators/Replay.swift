import Combine
import Foundation

/// Subject that replays a buffer of values to new subscribers.
///
/// Unlike `CurrentValueSubject`, can buffer multiple values (0 to N).
/// Thread-safe for concurrent subscriptions and emissions.
///
/// ```swift
/// let subject = ReplaySubject<Int, Never>(2)
/// subject.send(1)
/// subject.send(2)
/// subject.send(3)
///
/// // New subscriber receives last 2 values: [2, 3]
/// subject.sink { print($0) }
/// ```
public final class ReplaySubject<Output, Failure: Error>: Subject {

	private var buffer: [Output] = []
	private let bufferSize: Int
	private var subscriptions = [UUID: ReplaySubjectSubscription<Output, Failure>]()
	private var completion: Subscribers.Completion<Failure>?
	private let lock = Lock()

	/// Creates a replay subject with specified buffer size.
	///
	/// - Parameter bufferSize: Number of recent values to replay (0 = none)
	public init(_ bufferSize: Int = 0) {
		self.bufferSize = bufferSize
		buffer.reserveCapacity(bufferSize)
	}

	/// Provides this Subject an opportunity to establish demand for any new upstream subscriptions
	public func send(subscription: Subscription) {
		subscription.request(.unlimited)
	}

	/// Sends a value to the subscriber.
	public func send(_ value: Output) {
		lock.withLock {
			if bufferSize > 0 {
				buffer.removeFirst(Swift.max(0, buffer.count - bufferSize + 1))
				buffer.append(value)
			}
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
		let subscription = ReplaySubjectSubscription<Output, Failure>(AnySubscriber(subscriber)) { [weak self] in
			self?.cancel(id: id)
		}
		let (buffer, completion) = lock.withLock { () -> ([Output], Subscribers.Completion<Failure>?) in
			if self.completion == nil {
				subscriptions[id] = subscription
			}
			return (self.buffer, self.completion)
		}
		subscriber.receive(subscription: subscription)
		if !buffer.isEmpty || completion != nil {
			subscription.replay(buffer, completion: completion)
		}
	}

	private func cancel(id: UUID) {
		lock.withLock {
			subscriptions[id] = nil
		}
	}
}

private final class ReplaySubjectSubscription<Output, Failure: Error>: Subscription {

	private var downstream: AnySubscriber<Output, Failure>?
	private var demand: Subscribers.Demand = .none
	private var finish: () -> Void
	private let lock = Lock()

	public init(_ downstream: AnySubscriber<Output, Failure>, cancel: @escaping () -> Void) {
		self.downstream = downstream
		finish = cancel
	}

	/// Tells a publisher that it may send more values to the subscriber.
	public func request(_ newDemand: Subscribers.Demand) {
		lock.withLock {
			demand += newDemand
		}
	}

	public func cancel() {
		lock.withLock {
			defer {
				downstream = nil
				finish = {}
				demand = .none
			}
			return finish
		}()
	}

	public func receive(_ value: Output) {
		let (downstream, demand) = lock.withLock {
			(self.downstream, self.demand)
		}
		guard let downstream, demand > 0 else { return }
		let deltaDemand = downstream.receive(value)
		lock.withLock {
			if self.demand > 0 {
				self.demand -= 1
				self.demand += deltaDemand
			} else if deltaDemand > 0 {
				self.demand += deltaDemand - 1
			}
		}
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
		let (downstream, finish) = lock.withLock {
			defer {
				self.downstream = nil
				self.finish = {}
				demand = .none
			}
			return (self.downstream, self.finish)
		}
		guard let downstream else { return }
		downstream.receive(completion: completion)
		finish()
	}

	public func replay(_ values: [Output], completion: Subscribers.Completion<Failure>?) {
		var (downstream, demand) = lock.withLock {
			(self.downstream, self.demand)
		}
		guard let downstream, demand > 0 else { return }
		var deltaDemand: Int? = 0
		for value in values {
			guard demand > 0 else { break }
			demand -= 1
			deltaDemand = deltaDemand.flatMap { $0 - 1 }
			let newDemand = downstream.receive(value)
			demand += newDemand
			deltaDemand = deltaDemand.flatMap { i in newDemand.max.map { i + $0 } }
		}
		if let completion {
			receive(completion: completion)
		} else {
			lock.withLock {
				if let rawDemand = self.demand.max {
					if let deltaDemand {
						self.demand = .max(max(0, rawDemand + deltaDemand))
					} else {
						self.demand = .unlimited
					}
				}
			}
		}
	}
}

public extension Publisher {

	/// Shares publisher with replay capability for late subscribers.
	///
	/// - Parameter bufferSize: Number of values to replay (default: 0)
	///
	/// ```swift
	/// let shared = networkPublisher.share(replay: 1)
	/// // First subscriber triggers work
	/// shared.sink { print("A: \($0)") }
	/// // Second subscriber receives last value immediately
	/// shared.sink { print("B: \($0)") }
	/// ```
	func share(replay bufferSize: Int = 0) -> some Publisher<Output, Failure> {
		multicast(subject: ReplaySubject(bufferSize)).autoconnect()
	}
}
