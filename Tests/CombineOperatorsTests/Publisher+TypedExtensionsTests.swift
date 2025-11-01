import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("Publisher+TypedExtensions Tests")
struct PublisherTypedExtensionsTests {

	// MARK: - Bool Publishers: toggle()

	@Test("toggle inverts boolean values")
	func toggleInvertsBooleanValues() {
		let values = [true, false, true, false]
		var received: [Bool] = []

		let cancellable = values.publisher
			.toggle()
			.sink { value in
				received.append(value)
			}

		#expect(received == [false, true, false, true])
		cancellable.cancel()
	}

	@Test("toggle with all true values")
	func toggleWithAllTrueValues() {
		let values = [true, true, true]
		var received: [Bool] = []

		let cancellable = values.publisher
			.toggle()
			.sink { value in
				received.append(value)
			}

		#expect(received == [false, false, false])
		cancellable.cancel()
	}

	@Test("toggle with all false values")
	func toggleWithAllFalseValues() {
		let values = [false, false, false]
		var received: [Bool] = []

		let cancellable = values.publisher
			.toggle()
			.sink { value in
				received.append(value)
			}

		#expect(received == [true, true, true])
		cancellable.cancel()
	}

	@Test("toggle with subject")
	func toggleWithSubject() {
		let subject = PassthroughSubject<Bool, Never>()
		var received: [Bool] = []

		let cancellable = subject
			.toggle()
			.sink { value in
				received.append(value)
			}

		subject.send(true)
		subject.send(false)
		subject.send(true)

		#expect(received == [false, true, false])
		cancellable.cancel()
	}

	// MARK: - Collection Publishers: skipEqualSize()

	@Test("skipEqualSize removes duplicates based on count")
	func skipEqualSizeRemovesDuplicatesBasedOnCount() {
		let collections = [
			[1],
			[2],
			[3, 4],
			[5, 6],
			[7],
		]

		var received: [[Int]] = []

		let cancellable = collections.publisher
			.skipEqualSize()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		#expect(received[0] == [1])
		#expect(received[1] == [3, 4])
		#expect(received[2] == [7])

		cancellable.cancel()
	}

	@Test("skipEqualSize with strings")
	func skipEqualSizeWithStrings() {
		let strings = ["a", "bb", "cc", "ddd", "eee", "f"]
		var received: [String] = []

		let cancellable = strings.publisher
			.skipEqualSize()
			.sink { value in
				received.append(value)
			}

		#expect(received == ["a", "bb", "ddd", "f"])
		cancellable.cancel()
	}

	@Test("skipEqualSize with same size arrays")
	func skipEqualSizeWithSameSizeArrays() {
		let arrays = [[1, 2], [3, 4], [5, 6]]
		var received: [[Int]] = []

		let cancellable = arrays.publisher
			.skipEqualSize()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 1)
		#expect(received[0] == [1, 2])

		cancellable.cancel()
	}

	@Test("skipEqualSize with empty collections")
	func skipEqualSizeWithEmptyCollections() {
		let arrays: [[Int]] = [[], [], [1], [2], []]
		var received: [[Int]] = []

		let cancellable = arrays.publisher
			.skipEqualSize()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		#expect(received[0] == [])
		#expect(received[1] == [1])
		#expect(received[2] == [])

		cancellable.cancel()
	}

	// MARK: - Collection Publishers: nilIfEmpty

	@Test("nilIfEmpty returns nil for empty collections")
	func nilIfEmptyReturnsNilForEmptyCollections() {
		let arrays: [[Int]] = [[], [1], [2, 3], []]
		var received: [[Int]?] = []

		let cancellable = arrays.publisher
			.nilIfEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 4)
		#expect(received[0] == nil)
		#expect(received[1] == [1])
		#expect(received[2] == [2, 3])
		#expect(received[3] == nil)

		cancellable.cancel()
	}

	@Test("nilIfEmpty with strings")
	func nilIfEmptyWithStrings() {
		let strings = ["", "hello", "", "world"]
		var received: [String?] = []

		let cancellable = strings.publisher
			.nilIfEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 4)
		#expect(received[0] == nil)
		#expect(received[1] == "hello")
		#expect(received[2] == nil)
		#expect(received[3] == "world")

		cancellable.cancel()
	}

	@Test("nilIfEmpty with all empty collections")
	func nilIfEmptyWithAllEmptyCollections() {
		let arrays: [[Int]] = [[], [], []]
		var received: [[Int]?] = []

		let cancellable = arrays.publisher
			.nilIfEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received.allSatisfy { $0 == nil })
		#expect(received.count == 3)

		cancellable.cancel()
	}

	@Test("nilIfEmpty with all non-empty collections")
	func nilIfEmptyWithAllNonEmptyCollections() {
		let arrays = [[1], [2, 3], [4, 5, 6]]
		var received: [[Int]?] = []

		let cancellable = arrays.publisher
			.nilIfEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received.allSatisfy { $0 != nil })
		#expect(received.count == 3)

		cancellable.cancel()
	}

	// MARK: - Collection Publishers: isEmpty

	@Test("isEmpty maps to boolean")
	func isEmptyMapsToBolean() {
		let arrays: [[Int]] = [[], [1], [2, 3], []]
		var received: [Bool] = []

		let cancellable = arrays.publisher
			.isEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received == [true, false, false, true])
		cancellable.cancel()
	}

	@Test("isEmpty with strings")
	func isEmptyWithStrings() {
		let strings = ["", "hello", "", "world", ""]
		var received: [Bool] = []

		let cancellable = strings.publisher
			.isEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received == [true, false, true, false, true])
		cancellable.cancel()
	}

	@Test("isEmpty with dictionaries")
	func isEmptyWithDictionaries() {
		let dicts: [[String: Int]] = [[:], ["a": 1], [:]]
		var received: [Bool] = []

		let cancellable = dicts.publisher
			.isEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received == [true, false, true])
		cancellable.cancel()
	}

	// MARK: - Combining Collection Extensions

	@Test("Chaining skipEqualSize and isEmpty")
	func chainingSkipEqualSizeAndIsEmpty() {
		let arrays: [[Int]] = [[1], [2], [3, 4], [5, 6], []]
		var received: [Bool] = []

		let cancellable = arrays.publisher
			.skipEqualSize()
			.isEmpty
			.sink { value in
				received.append(value)
			}

		#expect(received == [false, false, true])
		cancellable.cancel()
	}

	@Test("Chaining nilIfEmpty and compactMap")
	func chainingNilIfEmptyAndCompactMap() {
		let arrays: [[Int]] = [[], [1], [2], []]
		var received: [[Int]] = []

		let cancellable = arrays.publisher
			.nilIfEmpty
			.compactMap { $0 }
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 2)
		#expect(received[0] == [1])
		#expect(received[1] == [2])

		cancellable.cancel()
	}

	// MARK: - Bool Publishers with Operators

	@Test("toggle with filter")
	func toggleWithFilter() {
		let values = [true, false, true, false]
		var received: [Bool] = []

		let cancellable = values.publisher
			.toggle()
			.filter { $0 } // Only true values
			.sink { value in
				received.append(value)
			}

		#expect(received == [true, true])
		cancellable.cancel()
	}

	@Test("toggle multiple times")
	func toggleMultipleTimes() {
		let values = [true, false]
		var received: [Bool] = []

		let cancellable = values.publisher
			.toggle()
			.toggle()
			.sink { value in
				received.append(value)
			}

		#expect(received == [true, false])
		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("Collection extensions with single element")
	func collectionExtensionsWithSingleElement() {
		let arrays = [[1]]
		var isEmpty: [Bool] = []
		var nilIfEmpty: [[Int]?] = []

		let cancellable1 = arrays.publisher
			.isEmpty
			.sink { isEmpty.append($0) }

		let cancellable2 = arrays.publisher
			.nilIfEmpty
			.sink { nilIfEmpty.append($0) }

		#expect(isEmpty == [false])
		#expect(nilIfEmpty == [[1]])

		cancellable1.cancel()
		cancellable2.cancel()
	}

	@Test("skipEqualSize with growing sizes")
	func skipEqualSizeWithGrowingSizes() {
		let arrays = [
			[1],
			[1, 2],
			[1, 2, 3],
			[1, 2, 3, 4],
		]

		var received: [[Int]] = []

		let cancellable = arrays.publisher
			.skipEqualSize()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 4) // All different sizes
		cancellable.cancel()
	}

	@Test("skipEqualSize with shrinking sizes")
	func skipEqualSizeWithShrinkingSizes() {
		let arrays = [
			[1, 2, 3, 4],
			[1, 2, 3],
			[1, 2],
			[1],
		]

		var received: [[Int]] = []

		let cancellable = arrays.publisher
			.skipEqualSize()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 4) // All different sizes
		cancellable.cancel()
	}

	// MARK: - Real-World Scenarios

	@Test("isEmpty for UI state management")
	func isEmptyForUIStateManagement() {
		let searchResults = [
			["Result 1"],
			[],
			["Result 2", "Result 3"],
			[],
		]

		var showEmptyState: [Bool] = []

		let cancellable = searchResults.publisher
			.isEmpty
			.sink { value in
				showEmptyState.append(value)
			}

		#expect(showEmptyState == [false, true, false, true])
		cancellable.cancel()
	}

	@Test("nilIfEmpty for optional handling")
	func nilIfEmptyForOptionalHandling() {
		let inputs = ["", "text", "", "more"]
		var processed: [String] = []

		let cancellable = inputs.publisher
			.nilIfEmpty
			.compactMap { $0 }
			.sink { value in
				processed.append(value)
			}

		#expect(processed == ["text", "more"])
		cancellable.cancel()
	}

	@Test("toggle for visibility states")
	func toggleForVisibilityStates() {
		let visibilityStates = [false, false, true, true]
		var invertedStates: [Bool] = []

		let cancellable = visibilityStates.publisher
			.toggle()
			.sink { value in
				invertedStates.append(value)
			}

		#expect(invertedStates == [true, true, false, false])
		cancellable.cancel()
	}
}
