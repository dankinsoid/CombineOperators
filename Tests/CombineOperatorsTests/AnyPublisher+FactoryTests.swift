import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("AnyPublisher Factory Methods Tests")
struct AnyPublisherFactoryTests {

	// MARK: - just(_:)

	@Test("just creates publisher with single value")
	func justCreatesPublisherWithSingleValue() async {
		let expectation = Expectation<Int>(limit: 1)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let cancellable = AnyPublisher<Int, Never>.just(42)
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received == [42])
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("just with string value")
	func justWithStringValue() async {
		let expectation = Expectation<String>(limit: 1)

		let cancellable = AnyPublisher<String, Never>.just("Hello")
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == ["Hello"])

		cancellable.cancel()
	}

	@Test("just with custom type")
	func justWithCustomType() async {
		struct User: Equatable {
			let id: Int
			let name: String
		}

		let expectation = Expectation<User>(limit: 1)
		let user = User(id: 1, name: "Alice")

		let cancellable = AnyPublisher<User, Never>.just(user)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [user])

		cancellable.cancel()
	}

	@Test("just with error failure type")
	func justWithErrorFailureType() async {
		enum TestError: Error { case test }

		let expectation = Expectation<Int>(limit: 1)

		let cancellable = AnyPublisher<Int, TestError>.just(42)
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values

		#expect(received == [42])

		cancellable.cancel()
	}

	// MARK: - never

	@Test("never creates publisher that never emits")
	func neverCreatesPublisherThatNeverEmits() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let cancellable = AnyPublisher<Int, Never>.never
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received.isEmpty)

		cancellable.cancel()
	}

	@Test("never does not complete")
	func neverDoesNotComplete() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let cancellable = AnyPublisher<Int, Never>.never
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.isEmpty)

		cancellable.cancel()
	}

	// MARK: - from(_:) Variadic

	@Test("from variadic creates publisher from values")
	func fromVariadicCreatesPublisherFromValues() async {
		let expectation = Expectation<Int>(limit: 5)

		let cancellable = AnyPublisher<Int, Never>.from(1, 2, 3, 4, 5)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [1, 2, 3, 4, 5])

		cancellable.cancel()
	}

	@Test("from variadic with single value")
	func fromVariadicWithSingleValue() async {
		let expectation = Expectation<String>(limit: 1)

		let cancellable = AnyPublisher<String, Never>.from("Hello")
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == ["Hello"])

		cancellable.cancel()
	}

	@Test("from variadic with strings")
	func fromVariadicWithStrings() async {
		let expectation = Expectation<String>(limit: 3)

		let cancellable = AnyPublisher<String, Never>.from("A", "B", "C")
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == ["A", "B", "C"])

		cancellable.cancel()
	}

	// MARK: - from(_:) Sequence

	@Test("from sequence creates publisher from array")
	func fromSequenceCreatesPublisherFromArray() async {
		let expectation = Expectation<Int>(limit: 4)

		let cancellable = AnyPublisher<Int, Never>.from([1, 2, 3, 4])
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [1, 2, 3, 4])

		cancellable.cancel()
	}

	@Test("from sequence with empty array")
	func fromSequenceWithEmptyArray() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let cancellable = AnyPublisher<Int, Never>.from([])
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("from sequence with range")
	func fromSequenceWithRange() async {
		let expectation = Expectation<Int>(limit: 10)

		let cancellable = AnyPublisher<Int, Never>.from(1...10)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == Array(1...10))

		cancellable.cancel()
	}

	@Test("from sequence with set")
	func fromSequenceWithSet() async {
		let expectation = Expectation<Int>(limit: 3)
		let inputSet: Set<Int> = [1, 2, 3]

		let cancellable = AnyPublisher<Int, Never>.from(inputSet)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received.count == 3)
		#expect(Set(received) == inputSet)

		cancellable.cancel()
	}

	// MARK: - failure(_:)

	@Test("failure creates publisher that immediately fails")
	func failureCreatesPublisherThatImmediatelyFails() async {
		enum TestError: Error, Equatable { case networkError }

		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let errorExpectation = Expectation<TestError>(limit: 1)

		let cancellable = AnyPublisher<Int, TestError>.failure(.networkError)
			.sink(
				receiveCompletion: { completion in
					if case .failure(let error) = completion {
						errorExpectation.fulfill(error)
					}
				},
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let errors = await errorExpectation.values

		#expect(received.isEmpty)
		#expect(errors == [.networkError])

		cancellable.cancel()
	}

	@Test("failure with custom error type")
	func failureWithCustomErrorType() async {
		struct CustomError: Error, Equatable {
			let code: Int
			let message: String
		}

		let expectation = Expectation<String>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let errorExpectation = Expectation<CustomError>(limit: 1)
		let error = CustomError(code: 404, message: "Not Found")

		let cancellable = AnyPublisher<String, CustomError>.failure(error)
			.sink(
				receiveCompletion: { completion in
					if case .failure(let error) = completion {
						errorExpectation.fulfill(error)
					}
				},
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let errors = await errorExpectation.values

		#expect(received.isEmpty)
		#expect(errors.first?.code == 404)
		#expect(errors.first?.message == "Not Found")

		cancellable.cancel()
	}

	// MARK: - empty

	@Test("empty creates publisher that completes immediately")
	func emptyCreatesPublisherThatCompletesImmediately() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let cancellable = AnyPublisher<Int, Never>.empty
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("empty with error failure type")
	func emptyWithErrorFailureType() async {
		enum TestError: Error { case test }

		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let cancellable = AnyPublisher<Int, TestError>.empty
			.sink(
				receiveCompletion: { completion in
					if case .finished = completion {
						completionExpectation.fulfill(true)
					}
				},
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	// MARK: - Factory Method Combinations

	@Test("just followed by map")
	func justFollowedByMap() async {
		let expectation = Expectation<String>(limit: 1)

		let cancellable = AnyPublisher<Int, Never>.just(42)
			.map { "Value: \($0)" }
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == ["Value: 42"])

		cancellable.cancel()
	}

	@Test("from followed by filter")
	func fromFollowedByFilter() async {
		let expectation = Expectation<Int>(limit: 3)

		let cancellable = AnyPublisher<Int, Never>.from(1, 2, 3, 4, 5, 6)
			.filter { $0 % 2 == 0 }
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [2, 4, 6])

		cancellable.cancel()
	}

	@Test("failure with catch")
	func failureWithCatch() async {
		enum TestError: Error { case test }

		let expectation = Expectation<Int>(limit: 1)

		let cancellable = AnyPublisher<Int, TestError>.failure(.test)
			.catch(99)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [99])

		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("factory methods preserve type information")
	func factoryMethodsPreserveTypeInformation() async {
		let expectation = Expectation<Int>(limit: 1)

		let publisher: AnyPublisher<Int, Never> = AnyPublisher.just(42)

		let cancellable = publisher
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [42])

		cancellable.cancel()
	}

	@Test("from with large sequence")
	func fromWithLargeSequence() async {
		let expectation = Expectation<Int>(limit: 1000)
		let largeArray = Array(1...1000)

		let cancellable = AnyPublisher<Int, Never>.from(largeArray)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received.count == 1000)
		#expect(received == largeArray)

		cancellable.cancel()
	}

	// MARK: - Performance

	@Test("factory methods are efficient")
	func factoryMethodsAreEfficient() async {
		let expectation = Expectation<Int>(limit: 100)

		let cancellables = (1...100).map { value in
			AnyPublisher<Int, Never>.just(value)
				.sink { expectation.fulfill($0) }
		}

		let received = await expectation.values

		#expect(received.count == 100)
		#expect(Set(received) == Set(1...100))

		cancellables.forEach { $0.cancel() }
	}

	@Test("from handles rapid sequence emissions")
	func fromHandlesRapidSequenceEmissions() async {
		let expectation = Expectation<Int>(limit: 500)
		let sequence = Array(1...500)

		let cancellable = AnyPublisher<Int, Never>.from(sequence)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received.count == 500)
		#expect(received == sequence)

		cancellable.cancel()
	}
}
