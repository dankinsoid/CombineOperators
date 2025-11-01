import Combine
@testable import CombineOperators
import Testing

@Suite("Async Publisher Tests")
struct AsyncTests {

	// MARK: - Single Value Emission

	@Test("Single value from async operation")
	func singleValueFromAsyncOperation() async {
        let expectation = Expectation<Int>(limit: 1)
		let publisher = Publishers.Async<Int, Never> {
			return 42
		}

        let cancellable = publisher.sink {
            expectation.fulfill($0)
        }
		defer { cancellable.cancel() }

        let received = await expectation.values

		#expect(received == [42])
	}

	@Test("Single value from throwing async operation")
	func singleValueFromThrowingAsyncOperation() async {
		let publisher = Publishers.Async<String, Error> {
			return "success"
		}

        let expectation = Expectation<String>(limit: 1)
		let cancellable = publisher.sink(
			receiveCompletion: { _ in },
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

        let received = await expectation.values

		#expect(received == ["success"])
	}

	// MARK: - Multiple Value Emission

	@Test("Multiple values from async operation")
	func multipleValuesFromAsyncOperation() async {
		let publisher = Publishers.Async<Int, Never> { send in
			for i in 1...5 {
				send(i)
			}
		}

		let expectation = Expectation<Int>(limit: 5)
		let cancellable = publisher.sink { expectation.fulfill($0) }
		defer { cancellable.cancel() }

		let received = await expectation.values

		#expect(received == [1, 2, 3, 4, 5])
	}

	@Test("Multiple values from throwing async operation")
	func multipleValuesFromThrowingAsyncOperation() async {
		let publisher = Publishers.Async<String, Error> { send in
			send("first")
			send("second")
			send("third")
		}

		let expectation = Expectation<String>(limit: 3)
		let cancellable = publisher.sink(
			receiveCompletion: { _ in },
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		let received = await expectation.values

		#expect(received == ["first", "second", "third"])
	}

	// MARK: - Error Handling

	@Test("Handles thrown errors")
	func handlesThrownErrors() async {
		enum TestError: Error { case failed }

		let publisher = Publishers.Async<Int, Error> {
			throw TestError.failed
		}

        let expectation = Expectation<Error>(limit: 1)
		let cancellable = publisher.sink(
			receiveCompletion: {
                if case let .failure(e) = $0 { expectation.fulfill(e) }
			},
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

        let error = await expectation.values.first

		#expect(error != nil)
	}

	@Test("Values before error are delivered")
	func valuesBeforeErrorAreDelivered() async {
		enum TestError: Error { case failed }

		let expectation = Expectation<Int>(limit: 2)

		let publisher = Publishers.Async<Int, Error> { send in
			send(1)
			send(2)
			throw TestError.failed
		}

        let errorExpectation = Expectation<Error>(limit: 1)
		let cancellable = publisher.sink(
			receiveCompletion: {
                if case let .failure(e) = $0 { errorExpectation.fulfill(e) }
			},
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		let received = await expectation.values
        let error = await errorExpectation.values.first

		#expect(received == [1, 2])
		#expect(error != nil)
	}

	// MARK: - Completion

	@Test("Completes after async operation")
	func completesAfterAsyncOperation() async {
		let publisher = Publishers.Async<Int, Never> {
			return 1
		}

        let expectation = Expectation<Bool>(limit: 1)
		let cancellable = publisher.sink(
            receiveCompletion: { _ in expectation.fulfill(true) },
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

        let completed = await expectation.values.first ?? false

		#expect(completed)
	}

	@Test("Completes after multiple emissions")
	func completesAfterMultipleEmissions() async {
		let expectation = Expectation<Int>(limit: 3)

		let publisher = Publishers.Async<Int, Never> { send in
			send(1)
			send(2)
			send(3)
		}

        let completedExpectation = Expectation<Bool>(limit: 1)
		let cancellable = publisher.sink(
            receiveCompletion: { _ in completedExpectation.fulfill(true) },
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		_ = await expectation.values

        let completed = await completedExpectation.values.first ?? false

		#expect(completed)
	}

	// MARK: - Cancellation

	@Test("Can be cancelled")
	func canBeCancelled() async {
		var emissionCount = 0
        let cancellation = Locked(AnyCancellable())

		let publisher = Publishers.Async<Int, Never> { send in
			for i in 1...10 {
                guard !Task.isCancelled else { break }
				send(i)
				emissionCount += 1
                if i == 3 {
                    cancellation.wrappedValue.cancel()
                }
			}
		}

        let firstThreeExpectation = Expectation<Int>(limit: 3)
        let expectation = Expectation<Bool>(limit: 1)
        cancellation.wrappedValue = publisher
            .handleEvents(
                receiveCancel: {
                    expectation.fulfill(true)
                }
            )
            .sink(
                receiveValue: { firstThreeExpectation.fulfill($0) }
            )

        let received = await firstThreeExpectation.values

        let completed = await expectation.values.first ?? false

		// Emissions should stop after cancellation
        #expect(emissionCount == 3)
        #expect(received == [1, 2, 3])
        #expect(completed)
	}

	// MARK: - Type Variants

	@Test("Never failure type with multiple emissions")
	func neverFailureTypeWithMultipleEmissions() async {
		let expectation = Expectation<String>(limit: 3)

		let publisher = Publishers.Async<String, Never> { send in
			send("a")
			send("b")
			send("c")
		}

		let cancellable = publisher.sink { expectation.fulfill($0) }
		defer { cancellable.cancel() }

		let received = await expectation.values

		#expect(received == ["a", "b", "c"])
	}

	@Test("Error failure type with success")
	func errorFailureTypeWithSuccess() async {
		let expectation = Expectation<Int>(limit: 1)

		let publisher = Publishers.Async<Int, Error> { send in
			send(99)
		}

		var error: Error?
		let cancellable = publisher.sink(
			receiveCompletion: {
				if case let .failure(e) = $0 { error = e }
			},
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		let received = await expectation.values

		#expect(received == [99])
		#expect(error == nil)
	}

	// MARK: - Real-World Scenarios

	@Test("Simulates API call")
	func simulatesAPICall() async {
		struct User { let id: Int, name: String }

		let publisher = Publishers.Async<User, Error> {
			return User(id: 1, name: "John")
		}

		let expectation = Expectation<User>(limit: 1)

		let cancellable = publisher.sink(
			receiveCompletion: { _ in },
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		let users = await expectation.values
		let user = users.first

		#expect(user?.id == 1)
		#expect(user?.name == "John")
	}

	@Test("Simulates progress updates")
	func simulatesProgressUpdates() async {
		let publisher = Publishers.Async<Double, Never> { send in
			for progress in stride(from: 0.0, through: 1.0, by: 0.25) {
				send(progress)
			}
		}

		let expectation = Expectation<Double>(limit: 5)
		let cancellable = publisher.sink { expectation.fulfill($0) }
		defer { cancellable.cancel() }

		let progress = await expectation.values

		#expect(progress.count == 5)
		#expect(progress.first == 0.0)
		#expect(progress.last == 1.0)
	}

	@Test("Simulates data streaming")
	func simulatesDataStreaming() async {
		let publisher = Publishers.Async<String, Error> { send in
			let chunks = ["chunk1", "chunk2", "chunk3"]
			for chunk in chunks {
				send(chunk)
			}
		}

		let expectation = Expectation<String>(limit: 3)
		let cancellable = publisher.sink(
			receiveCompletion: { _ in },
			receiveValue: { expectation.fulfill($0) }
		)
		defer { cancellable.cancel() }

		let chunks = await expectation.values

		#expect(chunks == ["chunk1", "chunk2", "chunk3"])
	}

	// MARK: - Edge Cases

	@Test("Empty async operation")
	func emptyAsyncOperation() async {
		let publisher = Publishers.Async<Int, Never> { _ in
			// No emissions
		}

		var received: [Int] = []

        let expectation = Expectation<Void>(limit: 1)
		let cancellable = publisher.sink(
            receiveCompletion: { _ in expectation.fulfill(()) },
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

        let completed = await expectation.values.count == 1

		#expect(received == [])
		#expect(completed)
	}

	@Test("Immediate emission without delay")
	func immediateEmissionWithoutDelay() async {
		let publisher = Publishers.Async<String, Never> {
			return "immediate"
		}

		let expectation = Expectation<String>(limit: 1)
		let cancellable = publisher.sink { expectation.fulfill($0) }
		defer { cancellable.cancel() }

		let received = await expectation.values

		#expect(received == ["immediate"])
	}

	@Test("Multiple subscribers receive independent executions")
	func multipleSubscribersReceiveIndependentExecutions() async {
		let executionCount = Locked(0)

        let publisher = Publishers.Async<Int, Never> {
            executionCount.wrappedValue += 1
            return executionCount.wrappedValue
		}

		let expectation1 = Expectation<Int>(limit: 1)
		let expectation2 = Expectation<Int>(limit: 1)

		let cancellable1 = publisher.sink { expectation1.fulfill($0) }
		let cancellable2 = publisher.sink { expectation2.fulfill($0) }
		defer {
			cancellable1.cancel()
			cancellable2.cancel()
		}

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		// Each subscriber triggers independent execution
        #expect(executionCount.wrappedValue == 2)
		#expect(received1.first != received2.first)
	}
}
