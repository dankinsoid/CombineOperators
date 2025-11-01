import Combine
@testable import CombineCocoa
import Foundation
import Testing
import TestUtilities

@Suite("ControlEvent Tests")
struct ControlEventTests {

	// MARK: - Basic Functionality

	@Test("Creates control event from publisher")
	func createsControlEventFromPublisher() async {
		let subject = PassthroughSubject<Int, Never>()
		let controlEvent = ControlEvent(events: subject)
		let expectation = Expectation<Int>(limit: 2)

		let cancellable = controlEvent.sink { value in
			expectation.fulfill(value)
		}

		subject.send(1)
		subject.send(2)

		let received = await expectation.values
		#expect(received == [1, 2])
        cancellable.cancel()
	}

	// MARK: - Never Fails Guarantee

	@Test("Never fails guarantee")
	func neverFailsGuarantee() {
		let subject = PassthroughSubject<Int, Never>()
		let controlEvent = ControlEvent(events: subject)

		// Verify Failure type is Never
		func verifyNeverFails<P: Publisher>(_ publisher: P) where P.Failure == Never {
			// Compilation succeeds only if Failure == Never
		}

		verifyNeverFails(controlEvent.events)
	}

	// MARK: - Values Stream

	@Test("Async values stream")
	func asyncValuesStream() async {
		let subject = PassthroughSubject<Int, Never>()
		let controlEvent = ControlEvent(events: subject)

		Task {
			try? await Task.sleep(nanoseconds: 100_000_000)
			subject.send(1)
			subject.send(2)
			subject.send(3)
			subject.send(completion: .finished)
		}
        
        let expectation = Expectation<Int>(limit: 3)
        let cancellable = controlEvent.sink { value in
            expectation.fulfill(value)
        }
        defer { cancellable.cancel() }

        let values = await expectation.values
		#expect(values == [1, 2, 3])
	}

	// MARK: - Subscribe Methods

	@Test("Subscribe with closure")
	func subscribeWithClosure() async {
		let subject = PassthroughSubject<String, Never>()
		let controlEvent = ControlEvent(events: subject)
		let expectation = Expectation<String>(limit: 1)

		let cancellable = controlEvent.sink { value in
			expectation.fulfill(value)
		}
		defer { cancellable.cancel() }

		subject.send("test")

		let received = await expectation.values
		#expect(received == ["test"])
	}

	@Test("Subscribe operator")
	func subscribeOperator() async {
		let subject = PassthroughSubject<Int, Never>()
		let controlEvent = ControlEvent(events: subject)
		let expectation = Expectation<Int>(limit: 1)

		let cancellable = controlEvent => { value in
			expectation.fulfill(value)
		}
		defer { cancellable.cancel() }

		subject.send(42)

		let received = await expectation.values
		#expect(received == [42])
	}

	@Test("Subscribe to binder")
	func subscribeToBinder() async {
		let subject = PassthroughSubject<String, Never>()
		let controlEvent = ControlEvent(events: subject)
		let expectation = Expectation<String>(limit: 1)

		let target = NSObject()
		let binder = Binder(target) { _, value in
			expectation.fulfill(value)
		}

		controlEvent => binder

		subject.send("bound")

		let received = await expectation.values
		#expect(received == ["bound"])
	}

	// MARK: - Map and Transform

	@Test("Map transformation")
	func mapTransformation() async {
		let subject = PassthroughSubject<Int, Never>()
		let controlEvent = ControlEvent(events: subject)
		let expectation = Expectation<String>(limit: 2)

		let mapped = controlEvent.map { "\($0)" }

		let cancellable = mapped.sink { value in
			expectation.fulfill(value)
		}
        defer { cancellable.cancel() }

		subject.send(1)
		subject.send(2)

		let received = await expectation.values
		#expect(received == ["1", "2"])
	}

	@Test("FlatMap transformation")
	func flatMapTransformation() async {
		let subject = PassthroughSubject<Int, Never>()
		let controlEvent = ControlEvent(events: subject)
		let expectation = Expectation<Int>(limit: 3)

		let flatMapped = controlEvent.flatMap { value in
			Just(value * 2).eraseToAnyPublisher()
		}

		let cancellable = flatMapped.sink { value in
			expectation.fulfill(value)
		}
        defer { cancellable.cancel() }

		subject.send(1)
		subject.send(2)
		subject.send(3)

		let received = await expectation.values
		#expect(received == [2, 4, 6])
	}

	// MARK: - Multiple Subscriptions

	@Test("Multiple subscribers receive same events")
	func multipleSubscribersReceiveSameEvents() async {
		let subject = PassthroughSubject<Int, Never>()
        let controlEvent = ControlEvent(events: subject.share())
		let expectation1 = Expectation<Int>(limit: 2)
		let expectation2 = Expectation<Int>(limit: 2)

		let cancellable1 = controlEvent.sink { value in
			expectation1.fulfill(value)
		}
		let cancellable2 = controlEvent.sink { value in
			expectation2.fulfill(value)
		}
		defer {
			cancellable1.cancel()
			cancellable2.cancel()
		}

		subject.send(1)
		subject.send(2)

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1 == [1, 2])
		#expect(received2 == [1, 2])
	}
}
