import Combine
@testable import CombineCocoa
import Foundation
import Testing
import TestUtilities

@Suite("ControlProperty Tests")
struct ControlPropertyTests {

	// MARK: - Basic Functionality

	@Test("Creates control property")
	func createsControlProperty() async {
		let subject = CurrentValueSubject<String, Never>("initial")
		let controlProperty = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<String, Never>(onValue: { value in
				subject.send(value)
			})
		)

		let expectation = Expectation<String>(limit: 1)
		let cancellable = controlProperty.sink { value in
			expectation.fulfill(value)
		}
        defer { cancellable.cancel() }

		let received = await expectation.values
		#expect(received == ["initial"])
	}
    
	// MARK: - Bidirectional Binding

	@Test("Subscribe sends values to subscriber")
	func subscribeSendsValuesToSubscriber() async {
		var receivedValues: [String] = []
		let subject = CurrentValueSubject<String, Never>("initial")

		let controlProperty = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<String, Never>(onValue: { value in
				receivedValues.append(value)
			})
		)

		let publisher = PassthroughSubject<String, Never>()
		publisher.subscribe(controlProperty)

		publisher.send("value1")
		publisher.send("value2")

		try? await Task.sleep(nanoseconds: 100_000_000)

		#expect(receivedValues == ["value1", "value2"])
	}

	@Test("Bind to binder")
	func bindToBinder() async {
		let subject = CurrentValueSubject<Int, Never>(10)
		let controlProperty = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<Int, Never>()
		)

		let expectation = Expectation<Int>(limit: 2)
		let target = NSObject()
		let binder = Binder(target) { _, value in
			expectation.fulfill(value)
		}

		controlProperty => binder

		subject.send(20)

		let received = await expectation.values
		#expect(received == [10, 20])
	}

	// MARK: - Values Stream

	@Test("Async values stream")
	func asyncValuesStream() async {
		let subject = CurrentValueSubject<Int, Never>(1)
		let controlProperty = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<Int, Never>()
		)
        
        let expectation = Expectation<Int>(limit: 3)
        let cancellable = controlProperty.sink { value in
            expectation.fulfill(value)
        }
        
        defer { cancellable.cancel() }

		Task {
			try? await Task.sleep(nanoseconds: 100_000_000)
			subject.send(2)
			subject.send(3)
			try? await Task.sleep(nanoseconds: 100_000_000)
			subject.send(completion: .finished)
		}

        let values = await expectation.values
		#expect(values == [1, 2, 3])
	}

	// MARK: - Map and Transform

	@Test("Map transformation")
	func mapTransformation() async {
		let subject = CurrentValueSubject<Int, Never>(5)
		let controlProperty = ControlProperty(
            values: subject,
			valueSink: TestSubscriber<Int, Never>()
		)

		let expectation = Expectation<String>(limit: 2)
		let mapped = controlProperty.map { "\($0)" }

		let cancellable = mapped.sink { value in
			expectation.fulfill(value)
		}
        defer { cancellable.cancel() }

		subject.send(10)

		let received = await expectation.values
		#expect(received == ["5", "10"])
	}

	// MARK: - Subscriber Protocol

	@Test("Requests unlimited demand")
	func requestsUnlimitedDemand() {
		let subject = CurrentValueSubject<String, Never>("test")
		let controlProperty = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<String, Never>()
		)

		var requestedDemand: Subscribers.Demand?
		let subscription = TestSubscription { demand in
			requestedDemand = demand
		}

		controlProperty.receive(subscription: subscription)
		#expect(requestedDemand == .unlimited)
	}

	@Test("Forwards values to internal subscriber")
	func forwardsValuesToInternalSubscriber() {
		var receivedValues: [Int] = []
		let subject = CurrentValueSubject<Int, Never>(0)

		let internalSubscriber = TestSubscriber<Int, Never>(onValue: { value in
			receivedValues.append(value)
		})

		let controlProperty = ControlProperty(
            values: subject,
            valueSink: internalSubscriber
		)

		let subscription = TestSubscription { _ in }
		controlProperty.receive(subscription: subscription)

		_ = controlProperty.receive(1)
		_ = controlProperty.receive(2)
		_ = controlProperty.receive(3)

		#expect(receivedValues == [1, 2, 3])
	}

	// MARK: - Completion Handling

    @MainActor
	@Test("Ignores completion events")
	func ignoresCompletionEvents() {
        let completionReceived = Locked(false)
		let subject = CurrentValueSubject<String, Never>("test")

		let cancellation = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<String, Never>()
        ).sink(
            receiveCompletion: { _ in
                completionReceived.wrappedValue = true
            },
            receiveValue: { _ in }
        )

        subject.send(completion: .finished)

		// ControlProperty should not forward completion to subscriber
        #expect(!completionReceived.wrappedValue)
        cancellation.cancel()
	}

	// MARK: - Integration with Operators

	@Test("Works with subscribe operator")
	func worksWithSubscribeOperator() async {
		let subject = CurrentValueSubject<String, Never>("hello")
		let controlProperty = ControlProperty(
            values: subject,
            valueSink: TestSubscriber<String, Never>()
		)

		let expectation = Expectation<String>(limit: 1)

		let cancellable = controlProperty => { value in
			expectation.fulfill(value)
		}
		defer { cancellable.cancel() }

		let received = await expectation.values
		#expect(received == ["hello"])
	}
}
