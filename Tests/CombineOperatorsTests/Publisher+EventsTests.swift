import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("Publisher+Events Tests")
struct PublisherEventsTests {

	// MARK: - onValue()

	@Test("onValue performs side-effect for each value")
	func onValuePerformsSideEffectForEachValue() {
		var sideEffectValues: [Int] = []
		var receivedValues: [Int] = []

		let cancellable = [1, 2, 3].publisher
			.onValue { value in
				sideEffectValues.append(value)
			}
			.sink { value in
				receivedValues.append(value)
			}

		#expect(sideEffectValues == [1, 2, 3])
		#expect(receivedValues == [1, 2, 3])
		cancellable.cancel()
	}

	@Test("onValue does not modify values")
	func onValueDoesNotModifyValues() {
		var sideEffects: [String] = []
		var received: [Int] = []

		let cancellable = [1, 2, 3].publisher
			.onValue { value in
				sideEffects.append("value: \(value)")
			}
			.sink { value in
				received.append(value)
			}

		#expect(received == [1, 2, 3])
		#expect(sideEffects.count == 3)
		cancellable.cancel()
	}

	@Test("onValue with multiple subscribers")
	func onValueWithMultipleSubscribers() {
		let subject = PassthroughSubject<Int, Never>()
		var sideEffectCount = 0

		let publisher = subject.onValue { _ in
			sideEffectCount += 1
		}

		let cancellable1 = publisher.sink { _ in }
		let cancellable2 = publisher.sink { _ in }

		subject.send(1)

		// Side effect should happen twice (once per subscriber)
		#expect(sideEffectCount == 2)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - onFailure()

	@Test("onFailure performs side-effect on error")
	func onFailurePerformsSideEffectOnError() {
		enum TestError: Error { case test }

		var errorCaptured: Error?
		var completionReceived = false

		let cancellable = Fail<Int, TestError>(error: .test)
			.onFailure { error in
				errorCaptured = error
			}
			.sink(
				receiveCompletion: { completion in
					if case .failure = completion {
						completionReceived = true
					}
				},
				receiveValue: { _ in }
			)

		#expect(errorCaptured != nil)
		#expect(completionReceived)
		cancellable.cancel()
	}

	// MARK: - onFinished()

	@Test("onFinished performs side-effect on completion")
	func onFinishedPerformsSideEffectOnCompletion() {
		var finishedCalled = false

		let cancellable = Just(42)
			.onFinished {
				finishedCalled = true
			}
			.sink { _ in }

		#expect(finishedCalled)
		cancellable.cancel()
	}

	@Test("onFinished not called on failure")
	func onFinishedNotCalledOnFailure() {
		enum TestError: Error { case test }

		var finishedCalled = false

		let cancellable = Fail<Int, TestError>(error: .test)
			.onFinished {
				finishedCalled = true
			}
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)

		#expect(!finishedCalled)
		cancellable.cancel()
	}

	@Test("onFinished with subject completion")
	func onFinishedWithSubjectCompletion() {
		var finishedCalled = false
		let subject = PassthroughSubject<Int, Never>()

		let cancellable = subject
			.onFinished {
				finishedCalled = true
			}
			.sink { _ in }

		subject.send(1)
		subject.send(2)
		#expect(!finishedCalled)

		subject.send(completion: .finished)
		#expect(finishedCalled)

		cancellable.cancel()
	}

	// MARK: - onSubscribe()

	@Test("onSubscribe performs side-effect on subscription")
	func onSubscribePerformsSideEffectOnSubscription() {
		var subscriptionReceived: Subscription?

		let cancellable = Just(42)
			.onSubscribe { subscription in
				subscriptionReceived = subscription
			}
			.sink { _ in }

		#expect(subscriptionReceived != nil)
		cancellable.cancel()
	}

	@Test("onSubscribe called before values")
	func onSubscribeCalledBeforeValues() {
		var subscriptionReceived = false
		var valueReceived = false

		let cancellable = Just(42)
			.onSubscribe { _ in
				subscriptionReceived = true
				#expect(!valueReceived)
			}
			.sink { _ in
				valueReceived = true
				#expect(subscriptionReceived)
			}

		#expect(subscriptionReceived)
		#expect(valueReceived)
		cancellable.cancel()
	}

	// MARK: - onRequest()

	@Test("onRequest performs side-effect on demand")
	func onRequestPerformsSideEffectOnDemand() {
		var demandReceived: Subscribers.Demand?

		let cancellable = Just(42)
			.onRequest { demand in
				demandReceived = demand
			}
			.sink { _ in }

		#expect(demandReceived != nil)
		cancellable.cancel()
	}

	@Test("onRequest captures demand type")
	func onRequestCapturesDemandType() {
		var demands: [Subscribers.Demand] = []

		let cancellable = [1, 2, 3].publisher
			.onRequest { demand in
				demands.append(demand)
			}
			.sink { _ in }

		#expect(demands.count > 0)
		cancellable.cancel()
	}

	// MARK: - Chaining Event Handlers

	@Test("Chaining multiple event handlers")
	func chainingMultipleEventHandlers() {
		var subscriptionReceived = false
		var values: [Int] = []
		var finishedCalled = false

		let cancellable = [1, 2, 3].publisher
			.onSubscribe { _ in
				subscriptionReceived = true
			}
			.onValue { value in
				values.append(value)
			}
			.onFinished {
				finishedCalled = true
			}
			.sink { _ in }

		#expect(subscriptionReceived)
		#expect(values == [1, 2, 3])
		#expect(finishedCalled)
		cancellable.cancel()
	}

	@Test("All event handlers in error scenario")
	func allEventHandlersInErrorScenario() {
		enum TestError: Error { case test }

		var subscriptionReceived = false
		var values: [Int] = []
		var errorCaptured: Error?
		var finishedCalled = false

		let subject = PassthroughSubject<Int, TestError>()

		let cancellable = subject
			.onSubscribe { _ in
				subscriptionReceived = true
			}
			.onValue { value in
				values.append(value)
			}
			.onFailure { error in
				errorCaptured = error
			}
			.onFinished {
				finishedCalled = true
			}
			.sink(
				receiveCompletion: { _ in },
				receiveValue: { _ in }
			)

		subject.send(1)
		subject.send(2)
		subject.send(completion: .failure(.test))

		#expect(subscriptionReceived)
		#expect(values == [1, 2])
		#expect(errorCaptured != nil)
		#expect(!finishedCalled)

		cancellable.cancel()
	}

	// MARK: - Thread Safety

	@Test("onValue with concurrent emissions")
	func onValueWithConcurrentEmissions() async {
		let subject = PassthroughSubject<Int, Never>()
		let lock = Lock()
		var sideEffectValues: [Int] = []

		let cancellable = subject
			.onValue { value in
				lock.withLock {
					sideEffectValues.append(value)
				}
			}
			.sink { _ in }

		await withTaskGroup(of: Void.self) { group in
			for i in 0 ..< 100 {
				group.addTask {
					subject.send(i)
				}
			}
			await group.waitForAll()
		}

		#expect(sideEffectValues.count == 100)
		cancellable.cancel()
	}

	// MARK: - Integration with Other Operators

	@Test("Event handlers with map")
	func eventHandlersWithMap() {
		var originalValues: [Int] = []
		var mappedValues: [String] = []

		let cancellable = [1, 2, 3].publisher
			.onValue { value in
				originalValues.append(value)
			}
			.map { String($0) }
			.sink { value in
				mappedValues.append(value)
			}

		#expect(originalValues == [1, 2, 3])
		#expect(mappedValues == ["1", "2", "3"])
		cancellable.cancel()
	}

	@Test("Event handlers with filter")
	func eventHandlersWithFilter() {
		var beforeFilter: [Int] = []
		var afterFilter: [Int] = []

		let cancellable = [1, 2, 3, 4, 5].publisher
			.onValue { value in
				beforeFilter.append(value)
			}
			.filter { $0 % 2 == 0 }
			.sink { value in
				afterFilter.append(value)
			}

		#expect(beforeFilter == [1, 2, 3, 4, 5])
		#expect(afterFilter == [2, 4])
		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("onValue with empty publisher")
	func onValueWithEmptyPublisher() {
		var valueCalled = false
		var finishedCalled = false

		let cancellable = Empty<Int, Never>()
			.onValue { _ in
				valueCalled = true
			}
			.onFinished {
				finishedCalled = true
			}
			.sink { _ in }

		#expect(!valueCalled)
		#expect(finishedCalled)
		cancellable.cancel()
	}

	@Test("Multiple onValue handlers")
	func multipleOnValueHandlers() {
		var firstCall: [Int] = []
		var secondCall: [Int] = []

		let cancellable = [1, 2, 3].publisher
			.onValue { value in
				firstCall.append(value)
			}
			.onValue { value in
				secondCall.append(value)
			}
			.sink { _ in }

		#expect(firstCall == [1, 2, 3])
		#expect(secondCall == [1, 2, 3])
		cancellable.cancel()
	}

	@Test("Event handlers do not affect cancellation")
	func eventHandlersDoNotAffectCancellation() {
		var cancelCalled = false
		let subject = PassthroughSubject<Int, Never>()

		let cancellable = subject
			.handleEvents(receiveCancel: {
				cancelCalled = true
			})
			.onValue { _ in }
			.sink { _ in }

		cancellable.cancel()
		#expect(cancelCalled)
	}
}
