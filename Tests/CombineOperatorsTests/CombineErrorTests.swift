import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("CombineError Tests")
struct CombineErrorTests {

	// MARK: - Error Cases

	@Test("CombineError has condition case")
	func combineErrorHasConditionCase() {
		let error = CombineError.condition
		#expect(error == .condition)
	}

	@Test("CombineError has noElements case")
	func combineErrorHasNoElementsCase() {
		let error = CombineError.noElements
		#expect(error == .noElements)
	}

	@Test("CombineError has unknown case")
	func combineErrorHasUnknownCase() {
		let error = CombineError.unknown
		#expect(error == .unknown)
	}

	// MARK: - Error Equality

	@Test("CombineError cases are distinct")
	func combineErrorCasesAreDistinct() {
		let condition = CombineError.condition
		let noElements = CombineError.noElements
		let unknown = CombineError.unknown

		#expect(condition != noElements)
		#expect(condition != unknown)
		#expect(noElements != unknown)
	}

	// MARK: - Error as Swift Error Protocol

	@Test("CombineError conforms to Error protocol")
	func combineErrorConformsToErrorProtocol() {
		let error: Error = CombineError.condition
		#expect(error is CombineError)
	}

	@Test("CombineError can be thrown")
	func combineErrorCanBeThrown() {
		func throwError() throws {
			throw CombineError.condition
		}

		#expect(throws: CombineError.self) {
			try throwError()
		}
	}

	@Test("CombineError can be caught")
	func combineErrorCanBeCaught() {
		var caughtError: CombineError?

		do {
			throw CombineError.noElements
		} catch let error as CombineError {
			caughtError = error
		} catch {
			// Should not reach here
		}

		#expect(caughtError == .noElements)
	}

	// MARK: - Pattern Matching

	// MARK: - Integration with Combine

	@Test("CombineError in Fail publisher")
	func combineErrorInFailPublisher() {
		var receivedError: CombineError?

		let cancellable = Fail<Int, CombineError>(error: .noElements)
			.sink(
				receiveCompletion: { completion in
					if case let .failure(error) = completion {
						receivedError = error
					}
				},
				receiveValue: { _ in }
			)

		#expect(receivedError == .noElements)
		cancellable.cancel()
	}

	@Test("CombineError in PassthroughSubject")
	func combineErrorInPassthroughSubject() {
		let subject = PassthroughSubject<Int, CombineError>()
		var receivedError: CombineError?

		let cancellable = subject
			.sink(
				receiveCompletion: { completion in
					if case let .failure(error) = completion {
						receivedError = error
					}
				},
				receiveValue: { _ in }
			)

		subject.send(completion: .failure(.condition))

		#expect(receivedError == .condition)
		cancellable.cancel()
	}

	// MARK: - Error Handling Operators

	@Test("CombineError with catch operator")
	func combineErrorWithCatchOperator() {
		var receivedValue: Int?

		let cancellable = Fail<Int, CombineError>(error: .unknown)
			.catch { _ in Just(42) }
			.sink { value in
				receivedValue = value
			}

		#expect(receivedValue == 42)
		cancellable.cancel()
	}

	@Test("CombineError with replaceError")
	func combineErrorWithReplaceError() {
		var receivedValue: Int?

		let cancellable = Fail<Int, CombineError>(error: .noElements)
			.replaceError(with: 99)
			.sink { value in
				receivedValue = value
			}

		#expect(receivedValue == 99)
		cancellable.cancel()
	}

	@Test("CombineError with retry")
	func combineErrorWithRetry() {
		var attemptCount = 0

		let cancellable = Deferred {
			Future<Int, CombineError> { promise in
				attemptCount += 1
				promise(.failure(.condition))
			}
		}
		.retry(2)
		.sink(
			receiveCompletion: { _ in },
			receiveValue: { _ in }
		)

		#expect(attemptCount == 3) // Initial + 2 retries
		cancellable.cancel()
	}

	// MARK: - Type Erasure

	@Test("CombineError with type erasure")
	func combineErrorWithTypeErasure() {
		var receivedError: Error?

		let publisher: AnyPublisher<Int, Error> = Fail<Int, CombineError>(error: .condition)
			.mapError { $0 as Error }
			.eraseToAnyPublisher()

		let cancellable = publisher
			.sink(
				receiveCompletion: { completion in
					if case let .failure(error) = completion {
						receivedError = error
					}
				},
				receiveValue: { _ in }
			)

		#expect(receivedError is CombineError)
		if let combineError = receivedError as? CombineError {
			#expect(combineError == .condition)
		}

		cancellable.cancel()
	}

	// MARK: - Error Descriptions

	@Test("CombineError provides error information")
	func combineErrorProvidesErrorInformation() {
		let errors = [
			CombineError.condition,
			CombineError.noElements,
			CombineError.unknown,
		]

		for error in errors {
			let errorAsAny: Any = error
			#expect(errorAsAny is CombineError)
		}
	}

	// MARK: - Multiple Error Types

	@Test("CombineError can be mapped to different error types")
	func combineErrorCanBeMappedToDifferentErrorTypes() {
		enum CustomError: Error {
			case custom
		}

		var receivedError: CustomError?

		let cancellable = Fail<Int, CombineError>(error: .unknown)
			.mapError { _ in CustomError.custom }
			.sink(
				receiveCompletion: { completion in
					if case let .failure(error) = completion {
						receivedError = error
					}
				},
				receiveValue: { _ in }
			)

		#expect(receivedError == .custom)
		cancellable.cancel()
	}

	// MARK: - Conditional Error Handling

	@Test("CombineError conditional error handling")
	func combineErrorConditionalErrorHandling() {
		var handledCondition = false
		var handledNoElements = false
		var handledUnknown = false

		let errors: [CombineError] = [.condition, .noElements, .unknown]

		for error in errors {
			switch error {
			case .condition:
				handledCondition = true
			case .noElements:
				handledNoElements = true
			case .unknown:
				handledUnknown = true
			}
		}

		#expect(handledCondition)
		#expect(handledNoElements)
		#expect(handledUnknown)
	}

	// MARK: - Error Recovery Patterns

	@Test("CombineError recovery with fallback")
	func combineErrorRecoveryWithFallback() {
		let subject = PassthroughSubject<Int, CombineError>()
		var receivedValues: [Int] = []

		let cancellable = subject
			.catch { error -> AnyPublisher<Int, Never> in
				switch error {
				case .condition:
					return Just(-1).eraseToAnyPublisher()
				case .noElements:
					return Just(-2).eraseToAnyPublisher()
				case .unknown:
					return Just(-3).eraseToAnyPublisher()
				}
			}
			.sink { value in
				receivedValues.append(value)
			}

		subject.send(1)
		subject.send(completion: .failure(.noElements))

		#expect(receivedValues == [1, -2])
		cancellable.cancel()
	}

	// MARK: - Error Propagation

	@Test("CombineError propagates through operators")
	func combineErrorPropagatesThroughOperators() {
		var receivedError: CombineError?

		let cancellable = Fail<Int, CombineError>(error: .condition)
			.map { $0 * 2 }
			.filter { $0 > 10 }
			.sink(
				receiveCompletion: { completion in
					if case let .failure(error) = completion {
						receivedError = error
					}
				},
				receiveValue: { _ in }
			)

		#expect(receivedError == .condition)
		cancellable.cancel()
	}
}
