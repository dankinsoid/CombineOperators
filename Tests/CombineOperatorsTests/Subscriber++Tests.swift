import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("Subscriber++ Tests")
struct SubscriberTests {

	// MARK: - Map

	@Test("Subscriber map transforms input values")
	func subscriberMapTransformsInput() async {
		let expectation = Expectation<Int>(limit: 3)

		let subscriber = TestSubscriber<Int, Never>(onValue: { expectation.fulfill($0) })
		let mappedSubscriber = subscriber.map { (string: String) in Int(string) ?? 0 }

		let publisher = ["10", "20", "30"].publisher
		publisher.subscribe(mappedSubscriber)

		let received = await expectation.values
		#expect(received == [10, 20, 30])
	}

	@Test("Subscriber map preserves completion")
	func subscriberMapPreservesCompletion() async {
		let expectation = Expectation<Bool>(limit: 1)

		let subscriber = TestSubscriber<Int, Never>(onFinished: {
			expectation.fulfill(true)
		})
		let mappedSubscriber = subscriber.map { (string: String) in Int(string) ?? 0 }

		let publisher = ["10"].publisher
		publisher.subscribe(mappedSubscriber)

		let completed = await expectation.values
		#expect(completed == [true])
	}

	// MARK: - MapFailure

	@Test("Subscriber mapFailure transforms error types")
	func subscriberMapFailureTransformsErrors() async {
		enum SourceError: Error { case source }
		enum TargetError: Error { case target }

		let expectation = Expectation<TargetError>(limit: 1)

		let subscriber = TestSubscriber<Int, TargetError>(onError: { error in
			expectation.fulfill(error)
		})
		let mappedSubscriber = subscriber.mapFailure { (_: SourceError) in TargetError.target }

		let publisher = Fail<Int, SourceError>(error: .source)
		publisher.subscribe(mappedSubscriber)

		let errors = await expectation.values
		#expect(errors.first == .target)
	}

	@Test("Subscriber mapFailure preserves values")
	func subscriberMapFailurePreservesValues() async {
		enum SourceError: Error { case source }
		enum TargetError: Error { case target }

		let expectation = Expectation<Int>(limit: 3)

		let subscriber = TestSubscriber<Int, TargetError>(onValue: { expectation.fulfill($0) })
		let mappedSubscriber = subscriber.mapFailure { (_: SourceError) in TargetError.target }

		let subject = PassthroughSubject<Int, SourceError>()
		subject.subscribe(mappedSubscriber)

		subject.send(1)
		subject.send(2)
		subject.send(3)

		let received = await expectation.values
		#expect(received == [1, 2, 3])
	}

	// MARK: - SetFailureType

	@Test("Subscriber setFailureType converts specific error to Error")
	func subscriberSetFailureTypeConvertsToGenericError() async {
		enum SpecificError: Error { case specific }

		let expectation = Expectation<Bool>(limit: 1)

		let subscriber = TestSubscriber<Int, Error>(onError: { _ in
			expectation.fulfill(true)
        })
		let typedSubscriber = subscriber.setFailureType(to: SpecificError.self)

		let publisher = Fail<Int, SpecificError>(error: .specific)
		publisher.subscribe(typedSubscriber)

		let errorReceived = await expectation.values
		#expect(errorReceived == [true])
	}

	// MARK: - OnCompletion

	@Test("Subscriber onCompletion executes action on finish")
	func subscriberOnCompletionExecutesOnFinish() async {
		let expectation = Expectation<Bool>(limit: 1)

		let subscriber = TestSubscriber<Int, Never>()
		let completionSubscriber = subscriber.onCompletion { _ in
			expectation.fulfill(true)
		}

		let publisher = [1, 2, 3].publisher
		publisher.subscribe(completionSubscriber)

		let completed = await expectation.values
		#expect(completed == [true])
	}

	@Test("Subscriber onCompletion executes action on error")
	func subscriberOnCompletionExecutesOnError() async {
		enum TestError: Error { case test }

		let expectation = Expectation<Subscribers.Completion<TestError>>(limit: 1)

		let subscriber = TestSubscriber<Int, TestError>()
		let completionSubscriber = subscriber.onCompletion { completion in
			expectation.fulfill(completion)
		}

		let publisher = Fail<Int, TestError>(error: .test)
		publisher.subscribe(completionSubscriber)

		let completions = await expectation.values
		if case .failure(let error) = completions.first {
			#expect(error == .test)
		} else {
			Issue.record("Expected failure completion")
		}
	}

	@Test("Subscriber onCompletion preserves values")
	func subscriberOnCompletionPreservesValues() async {
		let valueExpectation = Expectation<Int>(limit: 3)
		let completionExpectation = Expectation<Bool>(limit: 1)

		let subscriber = TestSubscriber<Int, Never>(onValue: { valueExpectation.fulfill($0) })
		let completionSubscriber = subscriber.onCompletion { _ in
			completionExpectation.fulfill(true)
		}

		let publisher = [1, 2, 3].publisher
		publisher.subscribe(completionSubscriber)

		let values = await valueExpectation.values
		let completed = await completionExpectation.values

		#expect(values == [1, 2, 3])
		#expect(completed == [true])
	}

	// MARK: - NonFailing

	@Test("Subscriber nonFailing converts to Never failure type")
	func subscriberNonFailingConvertsToNever() {
		let subscriber = TestSubscriber<Int, Error>()
		let nonFailingSubscriber = subscriber.nonFailing()

		// Type check - should compile with Never failure type
		let _: Subscribers.MapFailure<TestSubscriber<Int, Error>, Never> = nonFailingSubscriber
		#expect(true)
	}

	// MARK: - NonOptional

	@Test("Subscriber nonOptional unwraps optional values")
	func subscriberNonOptionalUnwrapsValues() async {
		let expectation = Expectation<Int?>(limit: 3)

		let subscriber = TestSubscriber<Int?, Never>(onValue: { expectation.fulfill($0) })
		let optionalSubscriber = subscriber.nonOptional()

		let publisher = [1, 2, 3].publisher
		publisher.subscribe(optionalSubscriber)

		let received = await expectation.values
		#expect(received == [1, 2, 3])
	}

	// MARK: - Combine Identifier

	@Test("Mapped subscriber preserves combine identifier")
	func mappedSubscriberPreservesCombineIdentifier() {
		let subscriber = TestSubscriber<Int, Never>()
		let mappedSubscriber = subscriber.map { (string: String) in Int(string) ?? 0 }

		#expect(subscriber.combineIdentifier == mappedSubscriber.combineIdentifier)
	}

	@Test("MapFailure subscriber preserves combine identifier")
	func mapFailureSubscriberPreservesCombineIdentifier() {
		enum TestError: Error { case test }

		let subscriber = TestSubscriber<Int, Error>()
		let mappedSubscriber = subscriber.mapFailure { (_: TestError) in NSError(domain: "", code: 0) }

		#expect(subscriber.combineIdentifier == mappedSubscriber.combineIdentifier)
	}

	// MARK: - Chaining

	@Test("Subscriber transformations can be chained")
	func subscriberTransformationsCanBeChained() async {
		enum SourceError: Error { case source }
		enum TargetError: Error { case target }

		let expectation = Expectation<Int>(limit: 2)

		let subscriber = TestSubscriber<Int, TargetError>(onValue: { expectation.fulfill($0) })
		let chainedSubscriber = subscriber
			.map { (string: String) in Int(string) ?? 0 }
			.mapFailure { (_: SourceError) in TargetError.target }
			.onCompletion { _ in }

		let subject = PassthroughSubject<String, SourceError>()
		subject.subscribe(chainedSubscriber)

		subject.send("10")
		subject.send("20")

		let received = await expectation.values
		#expect(received == [10, 20])
	}
}
