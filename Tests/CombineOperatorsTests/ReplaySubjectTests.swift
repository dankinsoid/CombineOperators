import Combine
@testable import CombineOperators
import Testing

@Suite("ReplaySubject Tests")
struct ReplaySubjectTests {

	// MARK: - Basic Functionality

	@Test("No replay with zero buffer size")
	func noReplayWithZeroBufferSize() {
		let subject = ReplaySubject<Int, Never>(0)
		subject.send(1)
		subject.send(2)

		var received: [Int] = []
		let cancellable = subject.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [])
	}

	@Test("Replays single value")
	func replaysSingleValue() {
		let subject = ReplaySubject<Int, Never>(1)
		subject.send(1)
		subject.send(2)

		var received: [Int] = []
		let cancellable = subject.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [2])
	}

	@Test("Replays multiple values")
	func replaysMultipleValues() {
		let subject = ReplaySubject<Int, Never>(3)
		subject.send(1)
		subject.send(2)
		subject.send(3)
		subject.send(4)

		var received: [Int] = []
		let cancellable = subject.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [2, 3, 4])
	}

	@Test("Buffer respects size limit")
	func bufferRespectsSizeLimit() {
		let subject = ReplaySubject<Int, Never>(2)

		for i in 1 ... 10 {
			subject.send(i)
		}

		var received: [Int] = []
		let cancellable = subject.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [9, 10])
	}

	// MARK: - Multiple Subscribers

	@Test("Multiple subscribers receive replays")
	func multipleSubscribersReceiveReplays() {
		let subject = ReplaySubject<Int, Never>(2)
		subject.send(1)
		subject.send(2)

		var received1: [Int] = []
		var received2: [Int] = []

		let cancellable1 = subject.sink { received1.append($0) }
		let cancellable2 = subject.sink { received2.append($0) }
		defer {
			cancellable1.cancel()
			cancellable2.cancel()
		}

		#expect(received1 == [1, 2])
		#expect(received2 == [1, 2])
	}

	@Test("Late subscriber receives prior values")
	func lateSubscriberReceivesPriorValues() {
		let subject = ReplaySubject<Int, Never>(1)

		var early: [Int] = []
		let cancellable1 = subject.sink { early.append($0) }
        defer { cancellable1.cancel() }

		subject.send(1)
		subject.send(2)

		var late: [Int] = []
		let cancellable2 = subject.sink { late.append($0) }
        defer { cancellable2.cancel() }

		subject.send(3)

		#expect(early == [1, 2, 3])
		#expect(late == [2, 3])
	}

	// MARK: - Completion

	@Test("Completion stops new values")
	func completionStopsNewValues() {
		let subject = ReplaySubject<Int, Never>(2)

		var received: [Int] = []
		var completed = false

		let cancellable = subject.sink(
			receiveCompletion: { _ in completed = true },
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

		subject.send(1)
		subject.send(completion: .finished)
		subject.send(2)

		#expect(received == [1])
		#expect(completed)
	}

	@Test("Subscribing after completion receives buffer and completion")
	func subscribingAfterCompletionReceivesBufferAndCompletion() {
		let subject = ReplaySubject<Int, Never>(2)
		subject.send(1)
		subject.send(2)
		subject.send(completion: .finished)

		var received: [Int] = []
		var completed = false

		let cancellable = subject.sink(
			receiveCompletion: { _ in completed = true },
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

		#expect(received == [1, 2])
		#expect(completed)
	}

	@Test("Failure completion")
	func failureCompletion() {
		enum TestError: Error { case test }
		let subject = ReplaySubject<Int, TestError>(2)

		subject.send(1)
		subject.send(2)
		subject.send(completion: .failure(.test))

		var received: [Int] = []
		var error: TestError?

		let cancellable = subject.sink(
			receiveCompletion: {
				if case let .failure(e) = $0 { error = e }
			},
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

		#expect(received == [1, 2])
		#expect(error != nil)
	}

	// MARK: - Cancellation

	@Test("Cancellation stops receiving values")
	func cancellationStopsReceivingValues() {
		let subject = ReplaySubject<Int, Never>(1)

		var received: [Int] = []
		let cancellable = subject.sink { received.append($0) }

		subject.send(1)
		cancellable.cancel()
		subject.send(2)

		#expect(received == [1])
	}

	@Test("Subscription requests unlimited demand")
	func subscriptionRequestsUnlimitedDemand() async {
		let subject = ReplaySubject<Int, Never>(0)

		await withCheckedContinuation { continuation in
			let subscription = TestSubscription {
				continuation.resume()
			}
			subject.send(subscription: subscription)
		}
	}

	// MARK: - Thread Safety

	@Test("Concurrent subscriptions")
	func concurrentSubscriptions() async {
		let subject = ReplaySubject<Int, Never>(10)

		await withTaskGroup(of: Void.self) { group in
			for i in 1 ... 100 {
				group.addTask {
					subject.send(i)
				}
			}

			for _ in 1 ... 10 {
				group.addTask {
					let cancellable = subject.sink { _ in }
					cancellable.cancel()
				}
			}
		}
	}

	// MARK: - Demand Management

	@Test("Respects demand limit")
	func respectsDemandLimit() {
		let subject = ReplaySubject<Int, Never>(0)
		var received: [Int] = []

		let subscriber = TestSubscriber<Int, Never>(
			demand: .max(2),
			onValue: { received.append($0) }
		)

		subject.subscribe(subscriber)

		subject.send(1)
		subject.send(2)
		subject.send(3)
		subject.send(4)

		#expect(received == [1, 2])
	}

	@Test("Accumulates demand properly")
	func accumulatesDemandProperly() {
		let subject = ReplaySubject<Int, Never>(0)
		var received: [Int] = []

		let subscriber = TestSubscriber<Int, Never>(
			demand: .max(1),
			onValue: { value in
				received.append(value)
			},
			additionalDemand: { _ in .max(1) }
		)

        subject.subscribe(subscriber)

		subject.send(1)
		subject.send(2)
		subject.send(3)

		#expect(received == [1, 2, 3])
	}

	@Test("Replay respects initial demand")
	func replayRespectsInitialDemand() {
		let subject = ReplaySubject<Int, Never>(5)

		subject.send(1)
		subject.send(2)
		subject.send(3)
		subject.send(4)
		subject.send(5)

		var received: [Int] = []
		let subscriber = TestSubscriber<Int, Never>(
			demand: .max(2),
			onValue: { received.append($0) }
		)

		subject.subscribe(subscriber)

		#expect(received == [1, 2])
	}

	@Test("Zero demand prevents value delivery")
	func zeroDemandPreventsValueDelivery() {
		let subject = ReplaySubject<Int, Never>(0)
		var received: [Int] = []

		let subscriber = TestSubscriber<Int, Never>(
			demand: .none,
			onValue: { received.append($0) }
		)

		subject.subscribe(subscriber)

		subject.send(1)
		subject.send(2)

		#expect(received == [])
	}

	@Test("Unlimited demand receives all values")
	func unlimitedDemandReceivesAllValues() {
		let subject = ReplaySubject<Int, Never>(3)

		subject.send(1)
		subject.send(2)
		subject.send(3)

		var received: [Int] = []
		let subscriber = TestSubscriber<Int, Never>(
			demand: .unlimited,
			onValue: { received.append($0) }
		)

		subject.subscribe(subscriber)

		subject.send(4)
		subject.send(5)

		#expect(received == [1, 2, 3, 4, 5])
	}

	@Test("Demand management with multiple subscribers")
	func demandManagementWithMultipleSubscribers() {
		let subject = ReplaySubject<Int, Never>(2)

		subject.send(1)
		subject.send(2)

		var received1: [Int] = []
		var received2: [Int] = []

		let subscriber1 = TestSubscriber<Int, Never>(
			demand: .max(1),
			onValue: { received1.append($0) }
		)

		let subscriber2 = TestSubscriber<Int, Never>(
			demand: .unlimited,
			onValue: { received2.append($0) }
		)

		subject.subscribe(subscriber1)
		subject.subscribe(subscriber2)

		subject.send(3)

		#expect(received1 == [1])
		#expect(received2 == [1, 2, 3])
	}

	@Test("Request additional demand after subscription")
	func requestAdditionalDemandAfterSubscription() throws {
		let subject = ReplaySubject<Int, Never>(0)
		var received: [Int] = []
		var subscription: Subscription?

		let subscriber = TestSubscriber<Int, Never>(
			demand: .max(1),
			onValue: { received.append($0) },
			onSubscription: { subscription = $0 }
		)

		subject.subscribe(subscriber)
        
        try #require(subscription != nil)

		subject.send(1)
		subject.send(2)

		#expect(received == [1])

        subscriber.demand = .max(2)
		subscription!.request(.max(2))

		subject.send(3)
		subject.send(4)

		#expect(received == [1, 3, 4])
	}

	@Test("Demand exhaustion stops delivery")
	func demandExhaustionStopsDelivery() {
		let subject = ReplaySubject<Int, Never>(0)
		var received: [Int] = []
		var demandExhausted = false

		let subscriber = TestSubscriber<Int, Never>(
			demand: .max(3),
			onValue: { value in
				received.append(value)
			},
			additionalDemand: { count in
				if count >= 3 {
					demandExhausted = true
					return .none
				}
				return .none
			}
		)

		subject.subscribe(subscriber)

		for i in 1...10 {
			subject.send(i)
		}

		#expect(received.count == 3)
		#expect(demandExhausted)
	}
}
