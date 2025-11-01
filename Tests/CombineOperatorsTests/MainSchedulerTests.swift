import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("MainScheduler Tests")
struct MainSchedulerTests {

	// MARK: - Synchronous Execution on Main Thread

	@Test("Executes synchronously when already on main thread")
	func executesSynchronouslyWhenAlreadyOnMainThread() async {
		await MainActor.run {
			var executed = false
			MainScheduler.instance.schedule(options: nil) {
				executed = true
			}
			// If synchronous, this will be true immediately
			#expect(executed)
		}
	}

	@Test("Executes on main thread from background")
	func executesOnMainThreadFromBackground() async {
		let expectation = Expectation<Bool>(limit: 1)

		await Task.detached {
			MainScheduler.instance.schedule(options: nil) {
				expectation.fulfill(Thread.isMainThread)
			}
		}.value

		let onMain = await expectation.values.first ?? false
		#expect(onMain)
	}

	// MARK: - MainActor Integration

	@MainActor
	@Test("syncSchedule executes MainActor closure")
	func syncScheduleExecutesMainActorClosure() {
		var executed = false
		MainScheduler.instance.syncSchedule {
			executed = true
		}
		#expect(executed)
	}

	@MainActor
	@Test("syncSchedule returns value from MainActor closure")
	func syncScheduleReturnsValueFromMainActorClosure() {
		let result = MainScheduler.instance.syncSchedule {
			42
		}
		#expect(result == 42)
	}

	@Test("syncSchedule from background thread executes on main")
	func syncScheduleFromBackgroundThreadExecutesOnMain() async {
		let result = await Task.detached {
			MainScheduler.instance.syncSchedule {
				Thread.isMainThread
			}
		}.value

		#expect(result)
	}

	// MARK: - Combine Integration

	@Test("Receive on MainScheduler delivers on main thread")
	func receiveOnMainSchedulerDeliversOnMainThread() async {
		let expectation = Expectation<Bool>(limit: 1)

		let cancellable = Just(42)
            .receive(on: MainScheduler.instance)
			.sink { _ in
				expectation.fulfill(Thread.isMainThread)
			}

		let onMain = await expectation.values.first ?? false
		cancellable.cancel()
		#expect(onMain)
	}

	@Test("MainScheduler with publisher from background thread")
	func mainSchedulerWithPublisherFromBackgroundThread() async {
		let expectation = Expectation<Int>(limit: 1)
		var cancellable: AnyCancellable?

		await Task.detached {
			cancellable = Just(42)
				.receive(on: MainScheduler.instance)
				.sink { value in
					expectation.fulfill(value)
				}
		}.value

		let received = await expectation.values
		cancellable?.cancel()
		#expect(received == [42])
	}

	// MARK: - Delayed Scheduling

	@Test("Schedule after date")
	func scheduleAfterDate() async {
		let expectation = Expectation<Bool>(limit: 1, timeLimit: 2)
		let scheduler = MainScheduler.instance
		let futureDate = scheduler.now.advanced(by: .milliseconds(100))

		scheduler.schedule(after: futureDate, tolerance: .zero, options: nil) {
			expectation.fulfill(true)
		}

		let executed = await expectation.values.first ?? false
		#expect(executed)
	}

	// MARK: - Thread Safety

	@Test("Concurrent scheduling from multiple threads")
	func concurrentSchedulingFromMultipleThreads() async {
		let expectation = Expectation<Int>(limit: 100, timeLimit: 2)

		await withTaskGroup(of: Void.self) { group in
			for i in 0 ..< 100 {
				group.addTask {
					MainScheduler.instance.schedule(options: nil) {
						expectation.fulfill(i)
					}
				}
			}
			await group.waitForAll()
		}

		let received = await expectation.values
		#expect(received.count == 100)
	}

	// MARK: - Performance Optimization

	@Test("Avoids unnecessary dispatch when on main thread")
	func avoidsUnnecessaryDispatchWhenOnMainThread() async {
        let executionCount = Locked(0)

		await MainActor.run {
			for _ in 0 ..< 100 {
				MainScheduler.instance.schedule(options: nil) {
                    executionCount.wrappedValue += 1
				}
			}
		}

        #expect(executionCount.wrappedValue == 100)
	}

	// MARK: - Error Handling

	@Test("Handles errors in scheduled closures")
	func handlesErrorsInScheduledClosures() async {
		let expectation = Expectation<Bool>(limit: 1)

		MainScheduler.instance.schedule(options: nil) {
			// This should not crash even if an error would be thrown
			expectation.fulfill(true)
		}

		let executed = await expectation.values.first ?? false
		#expect(executed)
	}

	// MARK: - Integration with Combine Operators

	@Test("Works with standard Combine operators")
	func worksWithStandardCombineOperators() async {
		let expectation = Expectation<String>(limit: 1)

		let cancellable = Just("test")
			.receive(on: MainScheduler.instance)
			.map { $0.uppercased() }
			.sink { value in
				expectation.fulfill(value)
			}

		let received = await expectation.values
		cancellable.cancel()
		#expect(received == ["TEST"])
	}

	@Test("Delivers errors on main thread")
	func deliversErrorsOnMainThread() async {
		enum TestError: Error { case test }

		let expectation = Expectation<Bool>(limit: 1)

		let cancellable = Fail<Int, TestError>(error: .test)
			.receive(on: MainScheduler.instance)
			.sink(
				receiveCompletion: { _ in
					expectation.fulfill(Thread.isMainThread)
				},
				receiveValue: { _ in }
			)

		let onMain = await expectation.values.first ?? false
		cancellable.cancel()
		#expect(onMain)
	}

	@Test("Maintains order of emitted values")
	func maintainsOrderOfEmittedValues() async {
		let expectation = Expectation<Int>(limit: 5)

		let cancellable = [1, 2, 3, 4, 5].publisher
			.receive(on: MainScheduler.instance)
			.sink { value in
				expectation.fulfill(value)
			}

		let received = await expectation.values
		cancellable.cancel()
		#expect(received == [1, 2, 3, 4, 5])
	}
}
