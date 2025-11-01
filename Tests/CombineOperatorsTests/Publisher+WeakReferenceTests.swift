import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("Publisher Weak Reference Tests")
struct PublisherWeakReferenceTests {

	// MARK: - with(weak:) for General Publishers

	@Test("with(weak:) combines output with weak reference")
	func withWeakCombinesOutputWithWeakReference() async throws {
		let expectation = Expectation<(NSObject, Int)>(limit: 3)
		let subject = PassthroughSubject<Int, Never>()
		let object = NSObject()

		let cancellable = subject
			.with(weak: object)
			.sink { expectation.fulfill($0) }
        
        defer {
            cancellable.cancel()
        }

		subject.send(1)
		subject.send(2)
		subject.send(3)

		let received = await expectation.values

		try #require(received.count == 3)
		#expect(received[0].1 == 1)
		#expect(received[1].1 == 2)
		#expect(received[2].1 == 3)
		#expect(received.allSatisfy { $0.0 === object })
	}

	@Test("with(weak:) completes when object deallocates")
	func withWeakCompletesWhenObjectDeallocates() async {
		let expectation = Expectation<Int>(limit: 2)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, Never>()

		var object: NSObject? = NSObject()
		weak var weakObject = object

		let cancellable = subject
			.with(weak: object)
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0.1) }
			)

		subject.send(1)
		subject.send(2)

		// Deallocate object
		object = nil

		// Object should be deallocated
		#expect(weakObject == nil)

		// Publisher should not emit after object is deallocated
		subject.send(3)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received == [1, 2])
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("with(weak:) handles nil object")
	func withWeakHandlesNilObject() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int, Never>()

		let cancellable = subject
			.with(weak: nil as NSObject?)
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0.1) }
			)

		subject.send(1)
		subject.send(2)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("with(weak:) multiple subscribers with same object")
	func withWeakMultipleSubscribersWithSameObject() async {
		let expectation1 = Expectation<Int>(limit: 2)
		let expectation2 = Expectation<Int>(limit: 2)
		let subject = PassthroughSubject<Int, Never>()
		let object = NSObject()

		let cancellable1 = subject
			.with(weak: object)
			.sink { expectation1.fulfill($0.1) }

		let cancellable2 = subject
			.with(weak: object)
			.sink { expectation2.fulfill($0.1) }

		subject.send(1)
		subject.send(2)

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1 == [1, 2])
		#expect(received2 == [1, 2])

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - with(weak:) for Void Publishers

	@Test("with(weak:) void publisher emits weak reference")
	func withWeakVoidPublisherEmitsWeakReference() async {
		let expectation = Expectation<NSObject>(limit: 3)
		let subject = PassthroughSubject<Void, Never>()
		let object = NSObject()

		let cancellable = subject
			.with(weak: object)
			.sink { expectation.fulfill($0) }
    
        defer {
            cancellable.cancel()
        }

		subject.send()
		subject.send()
		subject.send()

		let received = await expectation.values

		#expect(received.count == 3)
		#expect(received.allSatisfy { $0 === object })
	}

	@Test("with(weak:) void publisher completes when object deallocates")
	func withWeakVoidPublisherCompletesWhenObjectDeallocates() async {
		let expectation = Expectation<Int>(limit: 2)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Void, Never>()

		var object: NSObject? = NSObject()
		weak var weakObject = object

		let cancellable = subject
			.with(weak: object)
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { _ in expectation.fulfill(0) }
			)

		subject.send()
		subject.send()

		// Deallocate object
		object = nil

		// Object should be deallocated
		#expect(weakObject == nil)

		// Publisher should not emit after object is deallocated
		subject.send()

		let received = await expectation.values
        let completed = await completionExpectation.values.first ?? false

		#expect(received.count == 2)
		#expect(completed)

		cancellable.cancel()
	}

	@Test("with(weak:) void publisher handles nil object")
	func withWeakVoidPublisherHandlesNilObject() async {
		let expectation = Expectation<NSObject>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Void, Never>()

		let cancellable = subject
			.with(weak: nil as NSObject?)
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		subject.send()
		subject.send()

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	// MARK: - Error Handling with Weak References

	@Test("with(weak:) preserves error type")
	func withWeakPreservesErrorType() async {
		enum TestError: Error { case test }

		let expectation = Expectation<Int>(limit: 1)
		let errorExpectation = Expectation<TestError>(limit: 1)
		let subject = PassthroughSubject<Int, TestError>()
		let object = NSObject()

		let cancellable = subject
			.with(weak: object)
			.sink(
				receiveCompletion: { completion in
					if case .failure(let error) = completion {
						errorExpectation.fulfill(error)
					}
				},
				receiveValue: { expectation.fulfill($0.1) }
			)

		subject.send(1)
		subject.send(completion: .failure(.test))

		let received = await expectation.values
		let errors = await errorExpectation.values

		#expect(received == [1])
		#expect(errors.count == 1)

		cancellable.cancel()
	}

	// MARK: - Performance and Edge Cases

	@Test("with(weak:) handles rapid emissions")
	func withWeakHandlesRapidEmissions() async {
		let expectation = Expectation<Int>(limit: 100)
		let subject = PassthroughSubject<Int, Never>()
		let object = NSObject()

		let cancellable = subject
			.with(weak: object)
			.sink { expectation.fulfill($0.1) }

		for i in 1...100 {
			subject.send(i)
		}

		let received = await expectation.values

		#expect(received.count == 100)
		#expect(received == Array(1...100))

		cancellable.cancel()
	}

	@Test("with(weak:) works with custom classes")
	func withWeakWorksWithCustomClasses() async throws {
		class ViewModel {
			let name: String
			init(name: String) { self.name = name }
		}

		let expectation = Expectation<(ViewModel, Int)>(limit: 2)
		let subject = PassthroughSubject<Int, Never>()
		let viewModel = ViewModel(name: "Test")

		let cancellable = subject
			.with(weak: viewModel)
			.sink { expectation.fulfill($0) }
        
        defer {
            cancellable.cancel()
        }

		subject.send(1)
		subject.send(2)

		let received = await expectation.values

		try #require(received.count == 2)
		#expect(received[0].0.name == "Test")
		#expect(received[1].0.name == "Test")
		#expect(received[0].1 == 1)
		#expect(received[1].1 == 2)
	}
}
