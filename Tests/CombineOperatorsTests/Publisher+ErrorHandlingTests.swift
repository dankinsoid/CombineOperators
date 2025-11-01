import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("Publisher Error Handling Tests")
struct PublisherErrorHandlingTests {

	enum TestError: Error, Equatable {
		case networkError
		case validationError
		case unknownError
	}

	// MARK: - silenсeFailure()

	@Test("silenсeFailure completes silently on error")
	func silenсeFailureCompletesSilentlyOnError() async {
		let expectation = Expectation<Int>(limit: 2)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.silenсeFailure()
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		subject.send(1)
		subject.send(2)
		subject.send(completion: .failure(.networkError))

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received == [1, 2])
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("silenсeFailure emits no values after error")
	func silenсeFailureEmitsNoValuesAfterError() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.silenсeFailure()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(completion: .failure(.networkError))
		subject.send(2) // Should not emit

		let received = await expectation.values

		#expect(received == [1])

		cancellable.cancel()
	}

	@Test("silenсeFailure completes normally without error")
	func silenсeFailureCompletesNormallyWithoutError() async {
		let expectation = Expectation<Int>(limit: 3)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.silenсeFailure()
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		subject.send(1)
		subject.send(2)
		subject.send(3)
		subject.send(completion: .finished)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received == [1, 2, 3])
		#expect(completed.first == true)

		cancellable.cancel()
	}

	// MARK: - catch(_:)

	@Test("catch replaces failure with default value")
	func catchReplacesFailureWithDefaultValue() async {
		let expectation = Expectation<Int>(limit: 3)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.catch(99)
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(2)
		subject.send(completion: .failure(.networkError))

		let received = await expectation.values

		#expect(received == [1, 2, 99])

		cancellable.cancel()
	}

	@Test("catch emits default value and completes")
	func catchEmitsDefaultValueAndCompletes() async {
		let expectation = Expectation<String>(limit: 1)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let failingPublisher = Fail<String, TestError>(error: .validationError)

		let cancellable = failingPublisher
			.catch("default")
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received == ["default"])
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("catch with successful completion")
	func catchWithSuccessfulCompletion() async {
		let expectation = Expectation<Int>(limit: 3)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.catch(99)
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(2)
		subject.send(3)
		subject.send(completion: .finished)

		let received = await expectation.values

		// Default value should not be emitted on normal completion
		#expect(received == [1, 2, 3])

		cancellable.cancel()
	}

	// MARK: - eraseFailure()

	@Test("eraseFailure converts error to generic Error")
	func eraseFailureConvertsErrorToGenericError() async {
		let expectation = Expectation<Int>(limit: 1)
		let errorExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.eraseFailure()
			.sink(
				receiveCompletion: { completion in
					if case .failure(let error) = completion {
						#expect(error is TestError)
						errorExpectation.fulfill(true)
					}
				},
				receiveValue: { expectation.fulfill($0) }
			)

		subject.send(1)
		subject.send(completion: .failure(.networkError))

		let received = await expectation.values
		let errorReceived = await errorExpectation.values

		#expect(received == [1])
		#expect(errorReceived.first == true)

		cancellable.cancel()
	}

	// MARK: - asResult()

	@Test("asResult wraps values in success")
	func asResultWrapsValuesInSuccess() async throws {
		let expectation = Expectation<Result<Int, TestError>>(limit: 3)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.asResult()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(2)
		subject.send(3)

		let received = await expectation.values

		#expect(received.count == 3)
		#expect(try received[0].get() == 1)
		#expect(try received[1].get() == 2)
		#expect(try received[2].get() == 3)

		cancellable.cancel()
	}

	@Test("asResult wraps error in failure")
	func asResultWrapsErrorInFailure() async throws {
		let expectation = Expectation<Result<Int, TestError>>(limit: 3)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.asResult()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(2)
		subject.send(completion: .failure(.validationError))

		let received = await expectation.values

		#expect(received.count == 3)
		#expect(try received[0].get() == 1)
		#expect(try received[1].get() == 2)

		if case .failure(let error) = received[2] {
			#expect(error == .validationError)
		} else {
			Issue.record("Expected failure result")
		}

		cancellable.cancel()
	}

	@Test("asResult never fails")
	func asResultNeverFails() async {
		let expectation = Expectation<Result<Int, TestError>>(limit: 2)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.asResult()
			.sink(
				receiveCompletion: { completion in
					// Should complete, but not with failure
					if case .finished = completion {
						completionExpectation.fulfill(true)
					}
				},
				receiveValue: { expectation.fulfill($0) }
			)

		subject.send(1)
		subject.send(completion: .failure(.networkError))

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.count == 2)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("asResult with multiple errors")
	func asResultWithMultipleErrors() async throws {
		let expectation = Expectation<Result<Int, TestError>>(limit: 4)

		let publishers = [
            Just(1).setFailureType(to: TestError.self).eraseToAnyPublisher(),
            Fail<Int, TestError>(error: .networkError).eraseToAnyPublisher(),
            Just(2).setFailureType(to: TestError.self).eraseToAnyPublisher(),
            Fail<Int, TestError>(error: .validationError).eraseToAnyPublisher(),
		]

		for publisher in publishers {
			let cancellable = publisher
				.asResult()
				.sink { expectation.fulfill($0) }

			cancellable.cancel()
		}

		let received = await expectation.values

		#expect(received.count == 4)

		// Verify success and failure results
		#expect(try received[0].get() == 1)
		if case .failure(let error) = received[1] {
			#expect(error == .networkError)
		} else {
			Issue.record("Expected failure result")
		}
		#expect(try received[2].get() == 2)
		if case .failure(let error) = received[3] {
			#expect(error == .validationError)
		} else {
			Issue.record("Expected failure result")
		}
	}

	// MARK: - Operator Combinations

	@Test("chaining error handling operators")
	func chainingErrorHandlingOperators() async {
		let expectation = Expectation<Result<Int, Never>>(limit: 3)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.catch(99)
			.setFailureType(to: Never.self)
			.asResult()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(2)
		subject.send(completion: .failure(.networkError))

		let received = await expectation.values

		#expect(received.count == 3)
		#expect(received[0].get() == 1)
		#expect(received[1].get() == 2)
		#expect(received[2].get() == 99)

		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("error handling with empty publisher")
	func errorHandlingWithEmptyPublisher() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let emptyPublisher = Empty<Int, TestError>(completeImmediately: true)

		let cancellable = emptyPublisher
			.catch(99)
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

	@Test("error handling preserves threading")
	func errorHandlingPreservesThreading() async {
		let expectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.receive(on: DispatchQueue.main)
			.catch(99)
			.sink { _ in
				expectation.fulfill(Thread.isMainThread)
			}

		subject.send(completion: .failure(.networkError))

		let receivedOnMain = await expectation.values

		#expect(receivedOnMain.first == true)

		cancellable.cancel()
	}
}
