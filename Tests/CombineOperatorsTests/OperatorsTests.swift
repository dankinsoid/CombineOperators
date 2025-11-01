import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("Operator Tests")
struct OperatorsTests {

	// MARK: - Subscribe Operator (=>)

	@Test("Subscribe operator basic subscription")
	func subscribeOperatorBasicSubscription() async {
        let expectation = Expectation<Int>(limit: 2)
		let subject = PassthroughSubject<Int, Never>()

        let object = NSObject()
		let binder = Binder(object) { _, value in
            expectation.fulfill(value)
		}

		subject => binder

		subject.send(1)
		subject.send(2)
        
        let received = await expectation.values

		#expect(received == [1, 2])
	}

	@Test("Subscribe operator with closure")
	func subscribeOperatorWithClosure() {
		var received: [Int] = []
		let publisher = Just(42)

		let cancellable = publisher => { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [42])
	}

	@Test("Subscribe operator stores in set")
	func subscribeOperatorStoresInSet() {
		var cancellables = Set<AnyCancellable>()
		let publisher = Just(42)

		publisher.sink { _ in } => cancellables

		#expect(cancellables.count == 1)
	}

	@Test("Subscribe operator failure conversion")
	func subscribeOperatorFailureConversion() {
		enum TestError: Error { case test }

		let failingPublisher = Fail<Int, TestError>(error: .test)
		var errorReceived: Error?

		let subscription = TestSubscriber<Int, TestError>(onError: { error in
            errorReceived = error
		})

		failingPublisher => subscription

		#expect(errorReceived != nil)
	}

	@Test("Subscribe operator optional wrapping")
	func subscribeOperatorOptionalWrapping() async {
        let expectation = Expectation<Int>(limit: 1)
		let publisher = Just(42)

        let object = NSObject()
		let binder = Binder(object) { _, value in
            expectation.fulfill(value)
		}

		publisher => binder
        
        let received = await expectation.values

		#expect(received == [42])
	}

	// MARK: - MainScheduler Operator (==>)

	@Test("MainScheduler operator delivers on main thread")
	func MainSchedulerOperatorDeliversOnMainThread() async {
        let expectation = Expectation<Bool>(limit: 1)

		let publisher = Just(42)
        let object = NSObject()
		let binder = Binder<Int>(object) { _, _ in
            expectation.fulfill(Thread.isMainThread)
		}

		publisher ==> binder

        let receivedOnMain = await expectation.values.first ?? false

		#expect(receivedOnMain)
	}

	@Test("MainScheduler operator with main actor closure")
	func MainSchedulerOperatorWithMainActorClosure() async {
        let expectation = Expectation<Int>(limit: 1)

		let publisher = Just(42)

		let cancellable = publisher ==> { @MainActor value in
            expectation.fulfill(value)
		}
		defer { cancellable.cancel() }

        let received = await expectation.values

		#expect(received == [42])
	}

	// MARK: - RemoveDuplicates Operator (=>>)

	@Test("RemoveDuplicates operator filters duplicates")
	func removeDuplicatesOperatorFiltersDuplicates() async {
		let subject = PassthroughSubject<Int, Never>()
        let expectation = Expectation<Int>(limit: 3)

        let object = NSObject()
		let binder = Binder(object) { _, value in
            expectation.fulfill(value)
		}

		subject =>> binder

		subject.send(1)
		subject.send(1)
		subject.send(2)
		subject.send(2)
		subject.send(3)
        
        let received = await expectation.values

		#expect(received == [1, 2, 3])
	}

	@Test("RemoveDuplicates operator with closure")
	func removeDuplicatesOperatorWithClosure() {
		let values = [1, 1, 2, 2, 3, 3]
		var received: [Int] = []

		let cancellable = values.publisher =>> { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [1, 2, 3])
	}

	@Test("RemoveDuplicates operator non-consecutive duplicates")
	func removeDuplicatesOperatorNonConsecutiveDuplicates() {
		let values = [1, 2, 1, 3, 2]
		var received: [Int] = []

		let cancellable = values.publisher =>> { received.append($0) }
		defer { cancellable.cancel() }

		// Only consecutive duplicates are removed
		#expect(received == [1, 2, 1, 3, 2])
	}

	@Test("RemoveDuplicates operator with equatable struct")
	func removeDuplicatesOperatorWithEquatableStruct() {
		struct TestValue: Equatable {
			let id: Int
			let name: String
		}

		let values = [
			TestValue(id: 1, name: "A"),
			TestValue(id: 1, name: "A"),
			TestValue(id: 2, name: "B"),
		]

		var received: [TestValue] = []
		let cancellable = values.publisher =>> { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received.count == 2)
		#expect(received[0].id == 1)
		#expect(received[1].id == 2)
	}

	// MARK: - Operator Combinations

	@Test("Chaining operators")
	func chainingOperators() async {
		let subject = PassthroughSubject<Int, Never>()
		var received: [Int] = []
		var cancellables = Set<AnyCancellable>()

		subject =>> { received.append($0) } => cancellables

		subject.send(1)
		subject.send(1)
		subject.send(2)
    
		#expect(received == [1, 2])
		#expect(cancellables.count == 1)
	}

	// MARK: - Error Handling

	@Test("Operators with error publishers")
	func operatorsWithErrorPublishers() async {
		enum TestError: Error { case test }

		let subject = PassthroughSubject<Int, TestError>()
        let expectation = Expectation<Int>(limit: 1)
        let errorExpectation = Expectation<Bool>(limit: 1)

		let subscription = TestSubscriber<Int, Error>(
            onValue: { expectation.fulfill($0) },
            onError: { _ in errorExpectation.fulfill(true) }
		)

		subject => subscription

		subject.send(1)
		subject.send(completion: .failure(.test))
        
        let received = await expectation.values
        let errorReceived = await errorExpectation.values.first ?? false

		#expect(received == [1])
		#expect(errorReceived)
	}

	// MARK: - Thread Safety

	@Test("Concurrent operator usage")
	func concurrentOperatorUsage() async {
		let subject = PassthroughSubject<Int, Never>()
        let expectation = Expectation<Int>(limit: 100)

        let object = NSObject()
		let binder = Binder(object) { _, value in
            expectation.fulfill(value)
		}

		subject => binder

		await withTaskGroup(of: Void.self) { group in
			for i in 1 ... 100 {
				group.addTask {
					subject.send(i)
				}
			}
		}

        let received = await expectation.values

		#expect(received.count == 100)
	}
}
