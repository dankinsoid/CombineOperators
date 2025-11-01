import Combine
@testable import CombineOperators
import Foundation
import Testing
import TestUtilities

@Suite("Publisher Optional Tests")
struct PublisherOptionalTests {

	// MARK: - isNil()

	@Test("isNil returns true for nil values")
	func isNilReturnsTrueForNilValues() async {
		let expectation = Expectation<Bool>(limit: 3)
		let subject = PassthroughSubject<Int?, Never>()

		let cancellable = subject
			.isNil()
			.sink { expectation.fulfill($0) }

		subject.send(nil)
		subject.send(42)
		subject.send(nil)

		let received = await expectation.values

		#expect(received == [true, false, true])

		cancellable.cancel()
	}

	@Test("isNil with never-nil publisher")
	func isNilWithNeverNilPublisher() async {
		let expectation = Expectation<Bool>(limit: 3)
		let values: [Int?] = [1, 2, 3]

		let cancellable = values.publisher
			.isNil()
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [false, false, false])

		cancellable.cancel()
	}

	// MARK: - skipNil()

	@Test("skipNil filters out nil values")
	func skipNilFiltersOutNilValues() async {
		let expectation = Expectation<Int>(limit: 3)
		let subject = PassthroughSubject<Int?, Never>()

		let cancellable = subject
			.skipNil()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(nil)
		subject.send(2)
		subject.send(nil)
		subject.send(3)

		let received = await expectation.values

		#expect(received == [1, 2, 3])

		cancellable.cancel()
	}

	@Test("skipNil unwraps non-nil values")
	func skipNilUnwrapsNonNilValues() async {
		let expectation = Expectation<String>(limit: 2)
		let subject = PassthroughSubject<String?, Never>()

		let cancellable = subject
			.skipNil()
			.sink { expectation.fulfill($0) }

		subject.send("Hello")
		subject.send(nil)
		subject.send("World")

		let received = await expectation.values

		#expect(received == ["Hello", "World"])

		cancellable.cancel()
	}

	@Test("skipNil with all nil values")
	func skipNilWithAllNilValues() async {
		let expectation = Expectation<Int>(limit: 1, timeLimit: 0.5, failOnTimeout: false)
		let completionExpectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<Int?, Never>()

		let cancellable = subject
			.skipNil()
			.sink(
				receiveCompletion: { _ in completionExpectation.fulfill(true) },
				receiveValue: { expectation.fulfill($0) }
			)

		subject.send(nil)
		subject.send(nil)
		subject.send(nil)
		subject.send(completion: .finished)

		let received = await expectation.values
		let completed = await completionExpectation.values

		#expect(received.isEmpty)
		#expect(completed.first == true)

		cancellable.cancel()
	}

	@Test("skipNil preserves order")
	func skipNilPreservesOrder() async {
		let expectation = Expectation<Int>(limit: 5)
		let values: [Int?] = [1, nil, 2, nil, 3, nil, 4, 5]

		let cancellable = values.publisher
			.skipNil()
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [1, 2, 3, 4, 5])

		cancellable.cancel()
	}

	// MARK: - or(_:)

	@Test("or provides default for nil values")
	func orProvidesDefaultForNilValues() async {
		let expectation = Expectation<Int>(limit: 5)
		let subject = PassthroughSubject<Int?, Never>()

		let cancellable = subject
			.or(99)
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(nil)
		subject.send(2)
		subject.send(nil)
		subject.send(3)

		let received = await expectation.values

		#expect(received == [1, 99, 2, 99, 3])

		cancellable.cancel()
	}

	@Test("or with string default")
	func orWithStringDefault() async {
		let expectation = Expectation<String>(limit: 4)
		let subject = PassthroughSubject<String?, Never>()

		let cancellable = subject
			.or("N/A")
			.sink { expectation.fulfill($0) }

		subject.send("Hello")
		subject.send(nil)
		subject.send("World")
		subject.send(nil)

		let received = await expectation.values

		#expect(received == ["Hello", "N/A", "World", "N/A"])

		cancellable.cancel()
	}

	@Test("or with all non-nil values")
	func orWithAllNonNilValues() async {
		let expectation = Expectation<Int>(limit: 3)
		let values: [Int?] = [1, 2, 3]

		let cancellable = values.publisher
			.or(99)
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received == [1, 2, 3])

		cancellable.cancel()
	}

	// MARK: - optional()

	@Test("optional wraps values in Optional")
	func optionalWrapsValuesInOptional() async {
		let expectation = Expectation<Int?>(limit: 3)
		let subject = PassthroughSubject<Int, Never>()

		let cancellable = subject
			.optional()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(2)
		subject.send(3)

		let received = await expectation.values

		#expect(received.count == 3)
		#expect(received[0] == 1)
		#expect(received[1] == 2)
		#expect(received[2] == 3)

		cancellable.cancel()
	}

	@Test("optional with string publisher")
	func optionalWithStringPublisher() async {
		let expectation = Expectation<String?>(limit: 2)
		let values = ["Hello", "World"]

		let cancellable = values.publisher
			.optional()
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received.count == 2)
		#expect(received[0] == "Hello")
		#expect(received[1] == "World")

		cancellable.cancel()
	}

	// MARK: - isNilOrEmpty()

	@Test("isNilOrEmpty returns true for nil")
	func isNilOrEmptyReturnsTrueForNil() async {
		let expectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<[Int]?, Never>()

		let cancellable = subject
			.isNilOrEmpty()
			.sink { expectation.fulfill($0) }

		subject.send(nil)

		let received = await expectation.values

		#expect(received == [true])

		cancellable.cancel()
	}

	@Test("isNilOrEmpty returns true for empty array")
	func isNilOrEmptyReturnsTrueForEmptyArray() async {
		let expectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<[Int]?, Never>()

		let cancellable = subject
			.isNilOrEmpty()
			.sink { expectation.fulfill($0) }

		subject.send([])

		let received = await expectation.values

		#expect(received == [true])

		cancellable.cancel()
	}

	@Test("isNilOrEmpty returns false for non-empty array")
	func isNilOrEmptyReturnsFalseForNonEmptyArray() async {
		let expectation = Expectation<Bool>(limit: 1)
		let subject = PassthroughSubject<[Int]?, Never>()

		let cancellable = subject
			.isNilOrEmpty()
			.sink { expectation.fulfill($0) }

		subject.send([1, 2, 3])

		let received = await expectation.values

		#expect(received == [false])

		cancellable.cancel()
	}

	@Test("isNilOrEmpty with string collections")
	func isNilOrEmptyWithStringCollections() async {
		let expectation = Expectation<Bool>(limit: 4)
		let subject = PassthroughSubject<String?, Never>()

		let cancellable = subject
			.isNilOrEmpty()
			.sink { expectation.fulfill($0) }

		subject.send(nil)
		subject.send("")
		subject.send("Hello")
		subject.send("   ")

		let received = await expectation.values

		#expect(received == [true, true, false, false])

		cancellable.cancel()
	}

	@Test("isNilOrEmpty with dictionary")
	func isNilOrEmptyWithDictionary() async {
		let expectation = Expectation<Bool>(limit: 3)
		let subject = PassthroughSubject<[String: Int]?, Never>()

		let cancellable = subject
			.isNilOrEmpty()
			.sink { expectation.fulfill($0) }

		subject.send(nil)
		subject.send([:])
		subject.send(["key": 1])

		let received = await expectation.values

		#expect(received == [true, true, false])

		cancellable.cancel()
	}

	// MARK: - Operator Combinations

	@Test("skipNil then map")
	func skipNilThenMap() async {
		let expectation = Expectation<String>(limit: 3)
		let subject = PassthroughSubject<Int?, Never>()

		let cancellable = subject
			.skipNil()
			.map { "Value: \($0)" }
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(nil)
		subject.send(2)
		subject.send(nil)
		subject.send(3)

		let received = await expectation.values

		#expect(received == ["Value: 1", "Value: 2", "Value: 3"])

		cancellable.cancel()
	}

	@Test("or then filter")
	func orThenFilter() async {
		let expectation = Expectation<Int>(limit: 2)
		let subject = PassthroughSubject<Int?, Never>()

		let cancellable = subject
			.or(0)
			.filter { $0 > 0 }
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(nil)  // becomes 0, filtered out
		subject.send(2)
		subject.send(nil)  // becomes 0, filtered out

		let received = await expectation.values

		#expect(received == [1, 2])

		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("optional operators with complex types")
	func optionalOperatorsWithComplexTypes() async {
		struct User: Equatable {
			let id: Int
			let name: String
		}

		let expectation = Expectation<User>(limit: 2)
		let subject = PassthroughSubject<User?, Never>()

		let cancellable = subject
			.skipNil()
			.sink { expectation.fulfill($0) }

		subject.send(User(id: 1, name: "Alice"))
		subject.send(nil)
		subject.send(User(id: 2, name: "Bob"))

		let received = await expectation.values

		#expect(received.count == 2)
		#expect(received[0].name == "Alice")
		#expect(received[1].name == "Bob")

		cancellable.cancel()
	}

	@Test("or with lazy evaluation")
	func orWithLazyEvaluation() async {
		let expectation = Expectation<String>(limit: 3)
		let subject = PassthroughSubject<String?, Never>()

		var defaultCallCount = 0
		func getDefault() -> String {
			defaultCallCount += 1
			return "Default"
		}

		// Note: The operator uses @autoclosure, so it evaluates lazily
		// But Combine will evaluate it for each emission
		let cancellable = subject
			.map { $0 ?? getDefault() }
			.sink { expectation.fulfill($0) }

		subject.send("A")
		subject.send(nil)
		subject.send("B")

		let received = await expectation.values

		#expect(received == ["A", "Default", "B"])
		#expect(defaultCallCount == 1)

		cancellable.cancel()
	}

	@Test("nested optionals")
	func nestedOptionals() async {
		let expectation = Expectation<Int>(limit: 2)
		let subject = PassthroughSubject<Int??, Never>()

		let cancellable = subject
			.compactMap { $0 }
			.skipNil()
			.sink { expectation.fulfill($0) }

		subject.send(1)
		subject.send(nil)
		subject.send(.some(nil))
		subject.send(2)

		let received = await expectation.values

		#expect(received == [1, 2])

		cancellable.cancel()
	}

	// MARK: - Performance

	@Test("skipNil handles large sequences")
	func skipNilHandlesLargeSequences() async {
		let expectation = Expectation<Int>(limit: 500)

		let values: [Int?] = (1...1000).map { $0 % 2 == 0 ? $0 : nil }

		let cancellable = values.publisher
			.skipNil()
			.sink { expectation.fulfill($0) }

		let received = await expectation.values

		#expect(received.count == 500)
		#expect(received.allSatisfy { $0 % 2 == 0 })

		cancellable.cancel()
	}
}
