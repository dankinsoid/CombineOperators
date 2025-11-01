import Combine
@testable import CombineOperators
import Testing

@Suite("Create Publisher Tests")
struct CreateTests {

	// MARK: - Basic Functionality

	@Test("Emits single value")
	func emitsSingleValue() {
		let publisher = Publishers.Create<Int, Never> { subscriber in
			_ = subscriber.receive(42)
			subscriber.receive(completion: .finished)
			return ManualAnyCancellable()
		}

		var received: [Int] = []
		let cancellable = publisher.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [42])
	}

	@Test("Emits multiple values")
	func emitsMultipleValues() {
		let publisher = Publishers.Create<Int, Never> { subscriber in
			_ = subscriber.receive(1)
			_ = subscriber.receive(2)
			_ = subscriber.receive(3)
			subscriber.receive(completion: .finished)
			return ManualAnyCancellable()
		}

		var received: [Int] = []
		let cancellable = publisher.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [1, 2, 3])
	}

	@Test("Completes successfully")
	func completesSuccessfully() {
		let publisher = Publishers.Create<Int, Never> { subscriber in
			subscriber.receive(completion: .finished)
			return ManualAnyCancellable()
		}

		var completed = false
		let cancellable = publisher.sink(
			receiveCompletion: { _ in completed = true },
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

		#expect(completed)
	}

	@Test("Handles failure completion")
	func handlesFailureCompletion() {
		enum TestError: Error { case test }

		let publisher = Publishers.Create<Int, TestError> { subscriber in
			subscriber.receive(completion: .failure(.test))
			return ManualAnyCancellable()
		}

		var error: TestError?
		let cancellable = publisher.sink(
			receiveCompletion: {
				if case let .failure(e) = $0 { error = e }
			},
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

		#expect(error != nil)
	}

	// MARK: - Cancellation

	@Test("Invokes cancellation handler")
	func invokesCancellationHandler() {
		var cancelled = false

		let publisher = Publishers.Create<Int, Never> { subscriber in
			_ = subscriber.receive(1)
			return AnyCancellable { cancelled = true }
		}

		let cancellable = publisher.sink { _ in }
		#expect(!cancelled)

		cancellable.cancel()
		#expect(cancelled)
	}

	// MARK: - AnyPublisher.create

	@Test("AnyPublisher.create convenience method")
	func anyPublisherCreateConvenience() {
		let publisher = AnyPublisher<String, Never>.create { subscriber in
			_ = subscriber.receive("Hello")
			subscriber.receive(completion: .finished)
			return ManualAnyCancellable()
		}

		var received: [String] = []
		let cancellable = publisher.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == ["Hello"])
	}

	@Test("AnyPublisher.create with error type")
	func anyPublisherCreateWithError() {
		enum TestError: Error { case failed }

		let publisher = AnyPublisher<Int, TestError>.create { subscriber in
			_ = subscriber.receive(10)
			subscriber.receive(completion: .failure(.failed))
			return ManualAnyCancellable()
		}

		var received: [Int] = []
		var error: TestError?

		let cancellable = publisher.sink(
			receiveCompletion: {
				if case let .failure(e) = $0 { error = e }
			},
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

		#expect(received == [10])
		#expect(error != nil)
	}

	// MARK: - Demand Handling

	@Test("Executes only after demand")
	func executesOnlyAfterDemand() async throws {
		var executed = false

		let publisher = Publishers.Create<Int, Never> { subscriber in
			executed = true
			_ = subscriber.receive(1)
			return ManualAnyCancellable()
		}

		#expect(!executed)

        var subscription: Subscription?
		let subscriber = TestSubscriber<Int, Never>(
            demand: .none,
            onSubscription: {
                subscription = $0
            }
        )
		publisher.subscribe(subscriber)

        try #require(subscription != nil)
        
		#expect(!executed)

		subscriber.demand = .max(1)
        subscription!.request(.max(1))

		#expect(executed)
	}

	// MARK: - Thread Safety

	@Test("Concurrent subscriptions")
	func concurrentSubscriptions() async {
		let publisher = Publishers.Create<Int, Never> { subscriber in
			_ = subscriber.receive(42)
			subscriber.receive(completion: .finished)
			return ManualAnyCancellable()
		}

		await withTaskGroup(of: [Int].self) { group in
			for _ in 1...10 {
				group.addTask {
					var received: [Int] = []
					let cancellable = publisher.sink { received.append($0) }
					defer { cancellable.cancel() }
					return received
				}
			}

			var allReceived: [[Int]] = []
			for await result in group {
				allReceived.append(result)
			}

			for received in allReceived {
				#expect(received == [42])
			}
		}
	}

	// MARK: - Edge Cases

	@Test("Empty publisher")
	func emptyPublisher() {
		let publisher = Publishers.Create<Int, Never> { subscriber in
			subscriber.receive(completion: .finished)
			return ManualAnyCancellable()
		}

		var received: [Int] = []
		var completed = false

		let cancellable = publisher.sink(
			receiveCompletion: { _ in completed = true },
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

		#expect(received == [])
		#expect(completed)
	}

	@Test("Values without completion")
	func valuesWithoutCompletion() async {
		let expectation = Expectation<Int>(limit: 3)

		let publisher = Publishers.Create<Int, Never> { subscriber in
			_ = subscriber.receive(1)
			_ = subscriber.receive(2)
			_ = subscriber.receive(3)
			// No completion
			return ManualAnyCancellable()
		}

		var completed = false

		let cancellable = publisher.sink(
			receiveCompletion: { _ in completed = true },
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		let received = await expectation.values

		#expect(received == [1, 2, 3])
		#expect(!completed)
	}

	@Test("Cleanup on deinit")
	func cleanupOnDeinit() {
		var cleaned = false

		do {
			let publisher = Publishers.Create<Int, Never> { subscriber in
				_ = subscriber.receive(1)
				return AnyCancellable { cleaned = true }
			}

			let cancellable = publisher.sink { _ in }
			_ = cancellable
			// cancellable goes out of scope
		}

		// Subscription should be cleaned up
		#expect(cleaned)
	}
}
