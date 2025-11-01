import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("Cancellable++ Tests")
struct CancellableTests {

	// MARK: - AnyCancellable Variadic Init

	@Test("AnyCancellable variadic init cancels all subscriptions")
	func anyCancellableVariadicInitCancelsAll() {
		var cancelCount = 0

		let cancellable1 = ManualAnyCancellable { cancelCount += 1 }
		let cancellable2 = ManualAnyCancellable { cancelCount += 1 }
		let cancellable3 = ManualAnyCancellable { cancelCount += 1 }

		let bag = AnyCancellable(cancellable1, cancellable2, cancellable3)
		bag.cancel()

		#expect(cancelCount == 3)
	}

	@Test("AnyCancellable variadic init handles empty list")
	func anyCancellableVariadicInitHandlesEmpty() {
		let bag = AnyCancellable()
		bag.cancel()

		// Should not crash
		#expect(true)
	}

	// MARK: - AnyCancellable Sequence Init

	@Test("AnyCancellable sequence init cancels all subscriptions")
	func anyCancellableSequenceInitCancelsAll() {
		var cancelCount = 0

		let cancellables = [
			ManualAnyCancellable { cancelCount += 1 },
			ManualAnyCancellable { cancelCount += 1 },
			ManualAnyCancellable { cancelCount += 1 },
		]

		let bag = AnyCancellable(cancellables)
		bag.cancel()

		#expect(cancelCount == 3)
	}

	@Test("AnyCancellable sequence init handles empty sequence")
	func anyCancellableSequenceInitHandlesEmpty() {
		let cancellables: [Cancellable] = []
		let bag = AnyCancellable(cancellables)
		bag.cancel()

		// Should not crash
		#expect(true)
	}

	// MARK: - CancellableBuilder

	@Test("CancellableBuilder builds from multiple cancellables")
	func cancellableBuilderBuildsFromMultiple() {
		var cancelCount = 0

        let bag = AnyCancellable.build {
			ManualAnyCancellable { cancelCount += 1 }
			ManualAnyCancellable { cancelCount += 1 }
			ManualAnyCancellable { cancelCount += 1 }
		}

		bag.cancel()
		#expect(cancelCount == 3)
	}

	@Test("CancellableBuilder supports conditionals")
	func cancellableBuilderSupportsConditionals() {
		var cancelCount = 0
		let includeThird = true

        let bag = AnyCancellable.build {
			ManualAnyCancellable { cancelCount += 1 }
			ManualAnyCancellable { cancelCount += 1 }
			if includeThird {
				ManualAnyCancellable { cancelCount += 1 }
			}
		}

		bag.cancel()
		#expect(cancelCount == 3)
	}

	@Test("CancellableBuilder conditionals exclude when false")
	func cancellableBuilderConditionalsExcludeWhenFalse() {
		var cancelCount = 0
		let includeThird = false

        let bag = AnyCancellable.build {
			ManualAnyCancellable { cancelCount += 1 }
			ManualAnyCancellable { cancelCount += 1 }
			if includeThird {
				ManualAnyCancellable { cancelCount += 1 }
			}
		}

		bag.cancel()
		#expect(cancelCount == 2)
	}

	@Test("CancellableBuilder supports arrays")
	func cancellableBuilderSupportsArrays() {
		var cancelCount = 0

		let cancellables = [
			ManualAnyCancellable { cancelCount += 1 },
			ManualAnyCancellable { cancelCount += 1 },
		]

        let bag = AnyCancellable.build {
			ManualAnyCancellable { cancelCount += 1 }
			for cancellable in cancellables {
				cancellable
			}
		}

		bag.cancel()
		#expect(cancelCount == 3)
	}

	@Test("CancellableBuilder supports either/or branches")
	func cancellableBuilderSupportsEitherOr() {
		var firstCancelled = false
		var secondCancelled = false
		let useFirst = true

        let bag = AnyCancellable.build {
			if useFirst {
				ManualAnyCancellable { firstCancelled = true }
			} else {
				ManualAnyCancellable { secondCancelled = true }
			}
		}

		bag.cancel()
		#expect(firstCancelled)
		#expect(!secondCancelled)
	}

	// MARK: - ManualAnyCancellable

	@Test("ManualAnyCancellable executes cancel action")
	func manualAnyCancellableExecutesCancelAction() {
		var cancelled = false
		let cancellable = ManualAnyCancellable { cancelled = true }

		cancellable.cancel()
		#expect(cancelled)
	}

	@Test("ManualAnyCancellable empty init does nothing on cancel")
	func manualAnyCancellableEmptyInitDoesNothing() {
		let cancellable = ManualAnyCancellable()
		cancellable.cancel()

		// Should not crash
		#expect(true)
	}

	@Test("ManualAnyCancellable variadic init cancels all")
	func manualAnyCancellableVariadicInitCancelsAll() {
		var cancelCount = 0

		let cancellable = ManualAnyCancellable(
			ManualAnyCancellable { cancelCount += 1 },
			ManualAnyCancellable { cancelCount += 1 },
			ManualAnyCancellable { cancelCount += 1 }
		)

		cancellable.cancel()
		#expect(cancelCount == 3)
	}

	@Test("ManualAnyCancellable sequence init cancels all")
	func manualAnyCancellableSequenceInitCancelsAll() {
		var cancelCount = 0

		let cancellables = [
			ManualAnyCancellable { cancelCount += 1 },
			ManualAnyCancellable { cancelCount += 1 },
		]

		let cancellable = ManualAnyCancellable(cancellables)
		cancellable.cancel()

		#expect(cancelCount == 2)
	}

	@Test("ManualAnyCancellable can be cancelled multiple times")
	func manualAnyCancellableCanBeCancelledMultipleTimes() {
		var cancelCount = 0
		let cancellable = ManualAnyCancellable { cancelCount += 1 }

		cancellable.cancel()
		cancellable.cancel()
		cancellable.cancel()

		#expect(cancelCount == 3)
	}

	// MARK: - Real Publisher Integration

	@Test("CancellableBuilder works with real publishers")
	func cancellableBuilderWorksWithRealPublishers() async {
		let expectation = Expectation<Int>(limit: 2)

		let subject1 = PassthroughSubject<Int, Never>()
		let subject2 = PassthroughSubject<Int, Never>()

        let bag = AnyCancellable.build {
			subject1.sink { expectation.fulfill($0) }
			subject2.sink { expectation.fulfill($0) }
		}

		subject1.send(1)
		subject2.send(2)

		let received = await expectation.values
		#expect(received.sorted() == [1, 2])

		bag.cancel()
	}

	@Test("Cancelling bag stops all subscriptions")
	func cancellingBagStopsAllSubscriptions() async {
		var receivedAfterCancel = false
		let subject = PassthroughSubject<Int, Never>()

        let bag = AnyCancellable.build {
			subject.sink { _ in receivedAfterCancel = true }
		}

		bag.cancel()
		subject.send(1)

		#expect(!receivedAfterCancel)
	}

	// MARK: - Nested Builders

	@Test("CancellableBuilder supports nested builders")
	func cancellableBuilderSupportsNestedBuilders() {
		var cancelCount = 0

        let innerBag = AnyCancellable.build {
			ManualAnyCancellable { cancelCount += 1 }
			ManualAnyCancellable { cancelCount += 1 }
		}

        let outerBag = AnyCancellable.build {
			ManualAnyCancellable { cancelCount += 1 }
			innerBag
		}

		outerBag.cancel()
		#expect(cancelCount == 3)
	}

	// MARK: - Edge Cases

	@Test("CancellableBuilder handles single cancellable optimization")
	func cancellableBuilderHandlesSingleCancellableOptimization() {
		var cancelled = false
		let single = ManualAnyCancellable { cancelled = true }

		// Single cancellable should be returned as-is
		let result = CancellableBuilder.create(from: [single])
		result.cancel()

		#expect(cancelled)
	}

	@Test("Empty cancellable builder creates valid cancellable")
	func emptyCancellableBuilderCreatesValidCancellable() {
		let bag = AnyCancellable {
			// Empty builder
		}

		bag.cancel()
		// Should not crash
		#expect(true)
	}
}
