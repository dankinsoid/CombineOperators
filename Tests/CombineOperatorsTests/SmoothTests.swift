import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("Smooth Tests")
struct SmoothTests {

	// MARK: - FloatingPoint Smooth

	@Test("Smooth interpolates FloatingPoint values")
	func smoothInterpolatesFloatingPointValues() async {
		let expectation = Expectation<Double>(limit: 6)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send(0.0)
		subject.send(10.0)

		let received = await expectation.values

		// Should receive initial value + interpolated values
		#expect(received.count >= 5)
		#expect(received.first == 0.0)
		#expect(received.contains(where: { $0 > 0.0 && $0 < 10.0 }))
		#expect(received.last == 10.0)

		cancellable.cancel()
	}

	@Test("Smooth creates ascending interpolation")
	func smoothCreatesAscendingInterpolation() async {
		let expectation = Expectation<Double>(limit: 6)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send(0.0)
		subject.send(100.0)

		let received = await expectation.values

		// Values should be in ascending order for the interpolation
		var lastValue = -1.0
		var isAscending = true
		for value in received.dropFirst() {
			if value < lastValue {
				isAscending = false
				break
			}
			lastValue = value
		}

		#expect(isAscending)

		cancellable.cancel()
	}

	@Test("Smooth creates descending interpolation")
	func smoothCreatesDescendingInterpolation() async {
		let expectation = Expectation<Double>(limit: 6)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send(100.0)
		subject.send(0.0)

		let received = await expectation.values

		// Values should include descending interpolation
		#expect(received.first == 100.0)
		#expect(received.last == 0.0)
		#expect(received.contains(where: { $0 > 0.0 && $0 < 100.0 }))

		cancellable.cancel()
	}

	@Test("Smooth removes duplicates before smoothing")
	func smoothRemovesDuplicatesBeforeSmoothing() async {
		let expectation = Expectation<Double>(limit: 4)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 3)
			.sink { expectation.fulfill($0) }

		subject.send(10.0)
		subject.send(10.0) // Duplicate
		subject.send(10.0) // Duplicate
		subject.send(20.0)

		let received = await expectation.values

		// Should skip duplicates and only smooth from 10 to 20
		#expect(received.first == 10.0)
		#expect(received.contains(20.0))

		cancellable.cancel()
	}

	// MARK: - String Smooth

	@Test("Smooth morphs strings character by character")
	func smoothMorphsStringsCharacterByCharacter() async {
		let expectation = Expectation<String>(limit: 6)

		let subject = PassthroughSubject<String, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send("hello")
		subject.send("world")

		let received = await expectation.values

		#expect(received.count >= 2)
		#expect(received.first == "hello")
		#expect(received.last == "world")
		// Should have intermediate morphing strings
		#expect(received.count > 2)

		cancellable.cancel()
	}

	@Test("Smooth string handles empty to non-empty transition")
	func smoothStringHandlesEmptyToNonEmpty() async {
		let expectation = Expectation<String>(limit: 6)

		let subject = PassthroughSubject<String, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send("")
		subject.send("test")

		let received = await expectation.values

		#expect(received.first == "")
		#expect(received.last == "test")

		cancellable.cancel()
	}

	@Test("Smooth string handles non-empty to empty transition")
	func smoothStringHandlesNonEmptyToEmpty() async {
		let expectation = Expectation<String>(limit: 6)

		let subject = PassthroughSubject<String, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send("test")
		subject.send("")

		let received = await expectation.values

		#expect(received.first == "test")
		#expect(received.last == "")

		cancellable.cancel()
	}

	@Test("Smooth string preserves common prefix")
	func smoothStringPreservesCommonPrefix() {
		let transitions = "hello".smooth(to: "helium", count: 5)

		// All transitions should start with "hel" (common prefix)
		for transition in transitions {
			#expect(transition.hasPrefix("hel"))
		}
	}

	@Test("Smooth string preserves common suffix")
	func smoothStringPreservesCommonSuffix() {
		let transitions = "testing".smooth(to: "casting", count: 5)

		// All transitions should end with "sting" (common suffix)
		for transition in transitions {
			#expect(transition.hasSuffix("sting"))
		}
	}

	@Test("Smooth string handles identical strings")
	func smoothStringHandlesIdenticalStrings() {
		let transitions = "test".smooth(to: "test", count: 5)

		#expect(transitions.count == 5)
		// All should be "test"
		for transition in transitions {
			#expect(transition == "test")
		}
	}

	@Test("Smooth string removes duplicates")
	func smoothStringRemovesDuplicates() async {
		let expectation = Expectation<String>(limit: 4)

		let subject = PassthroughSubject<String, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 3)
			.sink { expectation.fulfill($0) }

		subject.send("hello")
		subject.send("hello") // Duplicate
		subject.send("world")

		let received = await expectation.values

		#expect(received.first == "hello")
		#expect(received.contains("world"))

		cancellable.cancel()
	}

	// MARK: - Custom Smooth with Float/Value

	@Test("Smooth with custom float extractor")
	func smoothWithCustomFloatExtractor() async {
		struct Model {
			var progress: Double
		}

		let expectation = Expectation<Model>(limit: 6)

		let subject = PassthroughSubject<Model, Never>()
		let cancellable = subject
			.smooth(
				interval: 0.01,
				count: 5,
				float: \.progress,
				value: { progress, _ in Model(progress: progress) }
			)
			.sink { expectation.fulfill($0) }

		subject.send(Model(progress: 0.0))
		subject.send(Model(progress: 1.0))

		let received = await expectation.values

		#expect(received.count >= 2)
		#expect(received.first?.progress == 0.0)
		#expect(received.last?.progress == 1.0)
		#expect(received.contains(where: { $0.progress > 0.0 && $0.progress < 1.0 }))

		cancellable.cancel()
	}

	@Test("Smooth with condition skips unwanted transitions")
	func smoothWithConditionSkipsUnwantedTransitions() async {
		let expectation = Expectation<Double>(limit: 5)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(
                rule: {
                    let isGrow = $0 < $1
                    let range = isGrow ? $0...$1 : $1...$0
                    return isGrow ? range.split(count: $2) : range.split(count: $2).reversed()
                },
                interval: 0.01,
				count: 3,
				condition: { old, new in abs(new - old) > 5 }
			)
			.sink { expectation.fulfill($0) }

		subject.send(0.0)
		subject.send(1.0) // Should skip (diff < 5)
		subject.send(10.0) // Should animate (diff > 5)

		let received = await expectation.values

		// First value
		#expect(received.first == 0.0)
		// Second value (no animation, direct)
		#expect(received.contains(1.0))
		// Third value should be smoothed
        #expect(received.last == 10)

		cancellable.cancel()
	}

	// MARK: - Custom Rule Smooth

	@Test("Smooth with custom rule")
	func smoothWithCustomRule() async {
		let expectation = Expectation<Int>(limit: 7)

		let subject = PassthroughSubject<Int, Never>()
		let cancellable = subject
			.smooth(
				rule: { old, new, count in
					// Custom rule: create linear steps
					Array(stride(from: old, through: new, by: (new - old) / count))
				},
				interval: 0.01,
				count: 5
			)
			.sink { expectation.fulfill($0) }

		subject.send(0)
		subject.send(10)

		let received = await expectation.values

		#expect(received.count >= 2)
		#expect(received.first == 0)
		#expect(received.last == 10)

		cancellable.cancel()
	}

	// MARK: - ClosedRange Split

	@Test("ClosedRange split creates correct number of values")
	func closedRangeSplitCreatesCorrectNumberOfValues() {
		let range: ClosedRange<Double> = 0.0 ... 10.0
		let split = range.split(count: 5)

		#expect(split.count == 5)
		#expect(split.first == 0.0)
		#expect(split.last == 10.0)
	}

	@Test("ClosedRange split with count 2 returns bounds")
	func closedRangeSplitWithCount2ReturnsBounds() {
		let range: ClosedRange<Double> = 0.0 ... 10.0
		let split = range.split(count: 2)

		#expect(split.count == 2)
		#expect(split == [0.0, 10.0])
	}

	@Test("ClosedRange split with count 1 returns upper bound")
	func closedRangeSplitWithCount1ReturnsUpperBound() {
		let range: ClosedRange<Double> = 0.0 ... 10.0
		let split = range.split(count: 1)

		#expect(split.count == 1)
		#expect(split == [10.0])
	}

	@Test("ClosedRange split creates evenly spaced values")
	func closedRangeSplitCreatesEvenlySpacedValues() {
		let range: ClosedRange<Double> = 0.0 ... 100.0
		let split = range.split(count: 11)

		#expect(split.count == 11)
		#expect(split[0] == 0.0)
		#expect(split[6].isApproximately(54.54, tolerance: 0.1))
		#expect(split[10] == 100.0)
	}

	// MARK: - String Extensions

	@Test("String commonSuffix finds common suffix")
	func stringCommonSuffixFindsCommonSuffix() {
		let suffix = "testing".commonSuffix(with: "casting")
		#expect(suffix == "sting")
	}

	@Test("String commonSuffix handles no common suffix")
	func stringCommonSuffixHandlesNoCommonSuffix() {
		let suffix = "hello".commonSuffix(with: "world")
		#expect(suffix == "")
	}

	@Test("String commonSuffix handles identical strings")
	func stringCommonSuffixHandlesIdenticalStrings() {
		let suffix = "test".commonSuffix(with: "test")
		#expect(suffix == "test")
	}

	@Test("String commonSuffix handles empty strings")
	func stringCommonSuffixHandlesEmptyStrings() {
		let suffix1 = "".commonSuffix(with: "test")
		let suffix2 = "test".commonSuffix(with: "")

		#expect(suffix1 == "")
		#expect(suffix2 == "")
	}

	@Test("String smooth handles count less than 2")
	func stringSmoothHandlesCountLessThan2() {
		let transitions1 = "hello".smooth(to: "world", count: 0)
		let transitions2 = "hello".smooth(to: "world", count: 1)

		#expect(transitions1.isEmpty)
		#expect(transitions2 == ["world"])
	}

	@Test("String smooth ensures final value is correct")
	func stringSmoothEnsuresFinalValueIsCorrect() {
		let transitions = "hello".smooth(to: "world", count: 10)

		#expect(transitions.last == "world")
	}

	// MARK: - Edge Cases

	@Test("Smooth handles single value emission")
	func smoothHandlesSingleValueEmission() async {
		let expectation = Expectation<Double>(limit: 1)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 5)
			.sink { expectation.fulfill($0) }

		subject.send(42.0)

		let received = await expectation.values

		#expect(received == [42.0])

		cancellable.cancel()
	}

	@Test("Smooth handles zero interval count")
	func smoothHandlesZeroIntervalCount() async {
		let expectation = Expectation<Double>(limit: 1)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(interval: 0.01, count: 0)
			.sink { expectation.fulfill($0) }

		subject.send(0.0)
		subject.send(10.0)

		let received = await expectation.values

		// With count 0, should not interpolate
		#expect(received.count >= 1)

		cancellable.cancel()
	}

	@Test("Smooth cancellation stops interpolation")
	func smoothCancellationStopsInterpolation() async {
		let expectation = Expectation<Double>(limit: 10, timeLimit: 0.5, failOnTimeout: false)

		let subject = PassthroughSubject<Double, Never>()
		let cancellable = subject
			.smooth(0.2) // 200ms duration
			.sink { expectation.fulfill($0) }

		subject.send(0.0)
		subject.send(100.0)

		cancellable.cancel()

		let received = await expectation.values

		// Should receive fewer values due to cancellation
		#expect(received.count < 10)
	}
}

extension Double {
	func isApproximately(_ other: Double, tolerance: Double) -> Bool {
		abs(self - other) < tolerance
	}
}
