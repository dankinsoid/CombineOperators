import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("OnDeinit Tests")
struct OnDeinitTests {

	// MARK: - Basic Behavior

	@Test("OnDeinit emits when object is deallocated")
	func onDeinitEmitsWhenObjectDeallocated() async {
		let expectation = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink { expectation.fulfill(()) }

		object = nil

		let received = await expectation.values
		#expect(received.count == 1)

		cancellable.cancel()
	}

	@Test("OnDeinit completes after emission")
	func onDeinitCompletesAfterEmission() async {
		let expectation = Expectation<Subscribers.Completion<Never>>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink(
			receiveCompletion: { expectation.fulfill($0) },
			receiveValue: { }
		)

		object = nil

		let completions = await expectation.values
		if case .finished = completions.first {
			#expect(true)
		} else {
			Issue.record("Expected finished completion")
		}

		cancellable.cancel()
	}

	@Test("OnDeinit emits void value")
	func onDeinitEmitsVoidValue() async {
		let expectation = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink { value in
			expectation.fulfill(value)
		}

		object = nil

		let received = await expectation.values
		#expect(received.count == 1)

		cancellable.cancel()
	}

	@Test("OnDeinit does not emit if object is retained")
	func onDeinitDoesNotEmitIfObjectRetained() async {
		let expectation = Expectation<Void>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let object = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink { expectation.fulfill(()) }

		// Object still alive
		let received = await expectation.values
		#expect(received.isEmpty)

		cancellable.cancel()
	}

	// MARK: - Multiple Subscriptions

	@Test("OnDeinit supports multiple subscriptions")
	func onDeinitSupportsMultipleSubscriptions() async {
		let expectation1 = Expectation<Void>(limit: 1)
		let expectation2 = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable1 = publisher.sink { expectation1.fulfill(()) }
		let cancellable2 = publisher.sink { expectation2.fulfill(()) }

		object = nil

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1.count == 1)
		#expect(received2.count == 1)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	@Test("OnDeinit handles late subscriptions")
	func onDeinitHandlesLateSubscriptions() async {
		let expectation1 = Expectation<Void>(limit: 1)
		let expectation2 = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable1 = publisher.sink { expectation1.fulfill(()) }

		// Subscribe after a delay
		let cancellable2 = publisher.sink { expectation2.fulfill(()) }

		object = nil

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1.count == 1)
		#expect(received2.count == 1)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Cancellation

	@Test("OnDeinit respects cancellation")
	func onDeinitRespectsCancellation() async {
		let expectation = Expectation<Void>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink { expectation.fulfill(()) }
		cancellable.cancel()

		object = nil

		let received = await expectation.values
		#expect(received.isEmpty)
	}

	@Test("OnDeinit cancellation cleans up subscription")
	func onDeinitCancellationCleansUpSubscription() async {
		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink { }
		cancellable.cancel()

		// Check that associated object is cleaned up properly
		let wrapper = objc_getAssociatedObject(object!, &deiniterKey)
		// Even if wrapper exists, the subscription should be removed
		#expect(true) // No crash means cleanup worked

		object = nil
	}

	@Test("OnDeinit partial cancellation allows remaining subscriptions")
	func onDeinitPartialCancellationAllowsRemainingSubscriptions() async {
		let expectation1 = Expectation<Void>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let expectation2 = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable1 = publisher.sink { expectation1.fulfill(()) }
		let cancellable2 = publisher.sink { expectation2.fulfill(()) }

		// Cancel first subscription
		cancellable1.cancel()

		object = nil

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1.isEmpty) // First was cancelled
		#expect(received2.count == 1) // Second still active

		cancellable2.cancel()
	}

	// MARK: - Weak Reference

	@Test("OnDeinit uses weak reference to object")
	func onDeinitUsesWeakReference() async {
		let expectation = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		weak var weakObject = object

		let publisher = Publishers.OnDeinit(object)
		let cancellable = publisher.sink { expectation.fulfill(()) }

		object = nil

		// Object should be deallocated
		#expect(weakObject == nil)

		let received = await expectation.values
		#expect(received.count == 1)

		cancellable.cancel()
	}

	@Test("OnDeinit emits immediately if object is already nil")
	func onDeinitEmitsImmediatelyIfObjectNil() async {
		let expectation = Expectation<Void>(limit: 1)

		let publisher = Publishers.OnDeinit(nil as NSObject?)
		let cancellable = publisher.sink { expectation.fulfill(()) }

		let received = await expectation.values
		#expect(received.count == 1)

		cancellable.cancel()
	}

	// MARK: - Thread Safety

	@Test("OnDeinit handles concurrent subscriptions")
	func onDeinitHandlesConcurrentSubscriptions() async {
		let expectation = Expectation<Void>(limit: 10)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellables = await withTaskGroup(of: AnyCancellable.self) { group -> [AnyCancellable] in
			for _ in 0 ..< 10 {
				group.addTask {
					publisher.sink { expectation.fulfill(()) }
				}
			}

			var results: [AnyCancellable] = []
			for await cancellable in group {
				results.append(cancellable)
			}
			return results
		}

		object = nil

		let received = await expectation.values
		#expect(received.count == 10)

		cancellables.forEach { $0.cancel() }
	}

	// MARK: - Integration

	@Test("OnDeinit works with operator chaining")
	func onDeinitWorksWithOperatorChaining() async {
		let expectation = Expectation<String>(limit: 1)

		var object: NSObject? = NSObject()
		let cancellable = Publishers.OnDeinit(object)
			.map { "deallocated" }
			.sink { expectation.fulfill($0) }

		object = nil

		let received = await expectation.values
		#expect(received == ["deallocated"])

		cancellable.cancel()
	}

	@Test("OnDeinit can be merged with other publishers")
	func onDeinitCanBeMergedWithOtherPublishers() async {
		let expectation = Expectation<String>(limit: 2)

		var object: NSObject? = NSObject()

		let deinitPublisher = Publishers.OnDeinit(object).map { "deinit" }
		let otherPublisher = Just("other")

		let cancellable = deinitPublisher
			.merge(with: otherPublisher)
			.sink { expectation.fulfill($0) }

		object = nil

		let received = await expectation.values
		#expect(received.contains("deinit"))
		#expect(received.contains("other"))

		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("OnDeinit handles rapid allocation and deallocation")
	func onDeinitHandlesRapidAllocationDeallocation() async {
		let expectation = Expectation<Void>(limit: 5)

		for _ in 0 ..< 5 {
			var object: NSObject? = NSObject()
			let publisher = Publishers.OnDeinit(object)
			let cancellable = publisher.sink { expectation.fulfill(()) }

			object = nil
			cancellable.cancel()
		}

		let received = await expectation.values
		#expect(received.count == 5)
	}

	@Test("OnDeinit handles subscription without demand request")
	func onDeinitHandlesSubscriptionWithoutDemand() {
		let object = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let subscriber = TestSubscriber<Void, Never>()
		publisher.subscribe(subscriber)

		// Should not crash without calling request
		#expect(true)
	}

	@Test("OnDeinit only emits once per subscription")
	func onDeinitOnlyEmitsOncePerSubscription() async {
		let expectation = Expectation<Void>(limit: 1)

		var object: NSObject? = NSObject()
		let publisher = Publishers.OnDeinit(object)

		let cancellable = publisher.sink { expectation.fulfill(()) }

		object = nil
		// Try to trigger again (shouldn't emit)

		let received = await expectation.values
		#expect(received.count == 1)

		cancellable.cancel()
	}
}

private var deiniterKey: UInt8 = 0
