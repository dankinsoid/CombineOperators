import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("Binder Tests")
struct BinderTests {

	// MARK: - Basic Functionality

	@Test("Binds values to target")
	func bindsValuesToTarget() async {
		let target = TestTarget()
        let expectation = Expectation<String>(limit: 1)

        let binder = Binder(target) { target, value in
            expectation.fulfill(value)
        }

        let publisher = Just("test")
        publisher.subscribe(binder)
        
        let receivedValues = await expectation.values
    
		#expect(receivedValues == ["test"])
	}

	@Test("Uses main scheduler by default")
	func usesMainSchedulerByDefault() async {
		let target = TestTarget()
		var executedOnMain = false

		await withCheckedContinuation { cont in
			let binder = Binder<String>(target) { _, _ in
				executedOnMain = Thread.isMainThread
				cont.resume()
			}

			let publisher = Just("test")
			publisher.subscribe(binder)
		}

		#expect(executedOnMain)
	}

	@Test("Custom scheduler execution")
	func customSchedulerExecution() async {
		let target = TestTarget()
		let queue = DispatchQueue(label: "test.queue")
		var executedOnCustomQueue = false

		await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
			let binder = Binder<String>(target, scheduler: queue) { _, _ in
				executedOnCustomQueue = !Thread.isMainThread
				cont.resume()
			}

			let publisher = Just("test")
			publisher.subscribe(binder)
		}

		#expect(executedOnCustomQueue)
	}

	// MARK: - Weak Reference

	@MainActor
	@Test("Stops binding when target deallocates")
	func stopBindingWhenTargetDeallocates() {
		var receivedCount = 0
		let subject = PassthroughSubject<String, Never>()

		do {
			let target = TestTarget()
			let binder = Binder<String>(target) { _, _ in
				receivedCount += 1
			}
			subject.subscribe(binder)

			subject.send("first")
			#expect(receivedCount == 1)
		}

		subject.send("second")
		#expect(receivedCount == 1) // Target deallocated, no binding
	}

	@Test("Cancels subscription when target deallocates")
	func cancelsSubscriptionWhenTargetDeallocates() {
		var subscriptionCancelled = false
		let subject = PassthroughSubject<String, Never>()

		do {
			let target = TestTarget()
			let binder = Binder<String>(target) { _, _ in }

			subject
				.handleEvents(receiveCancel: { subscriptionCancelled = true })
				.subscribe(binder)

			#expect(!subscriptionCancelled)
		}

		#expect(subscriptionCancelled)
	}

	// MARK: - Subscriber Protocol

	@Test("Requests unlimited demand")
	func requestsUnlimitedDemand() {
		let target = TestTarget()
		let binder = Binder<String>(target) { _, _ in }

		var requestedDemand: Subscribers.Demand?
		let subscription = TestSubscription { demand in
			requestedDemand = demand
		}

		binder.receive(subscription: subscription)
		#expect(requestedDemand == .unlimited)
	}

	@Test("Returns unlimited demand on receive")
	func returnsUnlimitedDemandOnReceive() {
		let target = TestTarget()
		let binder = Binder<String>(target) { _, _ in }

		let subscription = TestSubscription { _ in }
		binder.receive(subscription: subscription)

		let demand = binder.receive("test")
		#expect(demand == .unlimited)
	}

	@Test("Returns none demand when target is nil")
	func returnsNoneDemandWhenTargetIsNil() {
		var target: TestTarget? = TestTarget()
		let binder = Binder<String>(target!) { _, _ in }
		target = nil

		let demand = binder.receive("test")
		#expect(demand == .none)
	}

	@Test("Ignores completion")
	func ignoresCompletion() {
		let target = TestTarget()
		var completionReceived = false

		let binder = Binder<String>(target) { _, _ in
			completionReceived = true
		}

		binder.receive(completion: .finished)
		#expect(!completionReceived)
	}

	// MARK: - Thread Safety

	@Test("Main thread check optimization")
	func mainThreadCheckOptimization() async {
		let target = TestTarget()
        let expectation = Expectation<String>(limit: 2)

		let binder = Binder<String>(target) { _, string in
            expectation.fulfill(string)
		}

		// Simulate receiving on main thread
		await MainActor.run {
			_ = binder.receive("test1")
		}

		// Simulate receiving on background thread
		await Task.detached {
			_ = binder.receive("test2")
		}
		.value
        
        let receivedValues = await expectation.values

		// Wait for async operations
        #expect(receivedValues == ["test1", "test2"])
	}

	@Test("Concurrent binding attempts")
	func concurrentBindingAttempts() async {
		let target = TestTarget()
        let expectation = Expectation<Int>(limit: 100)

		let binder = Binder<Int>(target) {
            expectation.fulfill($1)
		}

		let subject = PassthroughSubject<Int, Never>()
		subject.subscribe(binder)

		await withTaskGroup(of: Void.self) { group in
			for i in 1 ... 100 {
				group.addTask {
					subject.send(i)
				}
			}
            await group.waitForAll()
		}
        
        let receivedValues = await expectation.values

        #expect(receivedValues.count == 100)
	}

	// MARK: - MainActor Isolation

	@Test("MainActor isolated binding")
	func mainActorIsolatedBinding() async {
		actor TestActor {
			var value = ""

			func update(_ newValue: String) {
				value = newValue
			}
		}

		let target = TestTarget()
        let expectation = Expectation<Bool>(limit: 1)

		let binder = Binder<String>(target) { _, _ in
            expectation.fulfill(true)
		}

		let publisher = Just("test")
		publisher.subscribe(binder)
        
        let bindingExecuted = await expectation.values.first ?? false

		#expect(bindingExecuted)
	}
}

// MARK: - Test Helpers

private final class TestTarget {
	var value = ""
}
