import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("Publisher+Transformations Tests")
struct PublisherTransformationsTests {

	// MARK: - interval()

	@Test("interval emits values at regular intervals")
	func intervalEmitsValuesAtRegularIntervals() async {
		let expectation = Expectation<Int>(limit: 3, timeLimit: 1)
		let subject = PassthroughSubject<Int, Never>()

		let cancellable = subject
			.interval(0.1)
			.sink { value in
				expectation.fulfill(value)
			}

		subject.send(1)
		subject.send(2)
		subject.send(3)

		let received = await expectation.values
		cancellable.cancel()

		#expect(received == [1, 2, 3])
	}

	// MARK: - withLast(initial:)

	@Test("withLast with initial value emits tuples")
	func withLastWithInitialValueEmitsTuples() {
		let publisher = [1, 2, 3].publisher
		var received: [(previous: Int, current: Int)] = []

		let cancellable = publisher
			.withLast(initial: 0)
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		#expect(received[0].previous == 0)
		#expect(received[0].current == 1)
		#expect(received[1].previous == 1)
		#expect(received[1].current == 2)
		#expect(received[2].previous == 2)
		#expect(received[2].current == 3)

		cancellable.cancel()
	}

	@Test("withLast with initial tracks state correctly")
	func withLastWithInitialTracksStateCorrectly() {
		let subject = PassthroughSubject<String, Never>()
		var received: [(previous: String, current: String)] = []

		let cancellable = subject
			.withLast(initial: "start")
			.sink { value in
				received.append(value)
			}

		subject.send("a")
		subject.send("b")

		#expect(received.count == 2)
		#expect(received[0].previous == "start")
		#expect(received[0].current == "a")
		#expect(received[1].previous == "a")
		#expect(received[1].current == "b")

		cancellable.cancel()
	}

	// MARK: - withLast()

	@Test("withLast without initial first emission has nil previous")
	func withLastWithoutInitialFirstEmissionHasNilPrevious() {
		let publisher = [1, 2, 3].publisher
		var received: [(previous: Int?, current: Int)] = []

		let cancellable = publisher
			.withLast()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		#expect(received[0].previous == nil)
		#expect(received[0].current == 1)
		#expect(received[1].previous == 1)
		#expect(received[1].current == 2)
		#expect(received[2].previous == 2)
		#expect(received[2].current == 3)

		cancellable.cancel()
	}

	@Test("withLast tracks previous values")
	func withLastTracksPreviousValues() {
		let values = ["a", "b", "c", "d"]
		var received: [(previous: String?, current: String)] = []

		let cancellable = values.publisher
			.withLast()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 4)
		#expect(received[0].previous == nil)
		#expect(received[1].previous == "a")
		#expect(received[2].previous == "b")
		#expect(received[3].previous == "c")

		cancellable.cancel()
	}

	// MARK: - value()

	@Test("value maps all outputs to constant")
	func valueMapsAllOutputsToConstant() {
		let publisher = [1, 2, 3].publisher
		var received: [String] = []

		let cancellable = publisher
			.value("constant")
			.sink { value in
				received.append(value)
			}

		#expect(received == ["constant", "constant", "constant"])
		cancellable.cancel()
	}

	@Test("value with different types")
	func valueWithDifferentTypes() {
		struct Event { let id: Int }
		let events = [Event(id: 1), Event(id: 2)]
		var received: [String] = []

		let cancellable = events.publisher
			.value("event")
			.sink { value in
				received.append(value)
			}

		#expect(received == ["event", "event"])
		cancellable.cancel()
	}

	// MARK: - any()

	@Test("any erases to AnyPublisher")
	func anyErasesToAnyPublisher() {
		let publisher = Just(42).any()
		#expect(type(of: publisher) == AnyPublisher<Int, Never>.self)
	}

	@Test("any preserves output type")
	func anyPreservesOutputType() {
		let publisher = [1, 2, 3].publisher.any()
		var received: [Int] = []

		let cancellable = publisher.sink { value in
			received.append(value)
		}

		#expect(received == [1, 2, 3])
		cancellable.cancel()
	}

	// MARK: - append()

	@Test("append adds values to end")
	func appendAddsValuesToEnd() {
		let publisher = [1, 2].publisher
		var received: [Int] = []

		let cancellable = publisher
			.append(3, 4, 5)
			.sink { value in
				received.append(value)
			}

		#expect(received == [1, 2, 3, 4, 5])
		cancellable.cancel()
	}

	@Test("append with empty sequence")
	func appendWithEmptySequence() {
		let publisher = [1, 2, 3].publisher
		var received: [Int] = []

		let cancellable = publisher
			.append()
			.sink { value in
				received.append(value)
			}

		#expect(received == [1, 2, 3])
		cancellable.cancel()
	}

	@Test("append with single value")
	func appendWithSingleValue() {
		let publisher = Just(1)
		var received: [Int] = []

		let cancellable = publisher
			.append(2)
			.sink { value in
				received.append(value)
			}

		#expect(received == [1, 2])
		cancellable.cancel()
	}

	// MARK: - andIsSame()

	@Test("andIsSame tracks keyPath changes")
	func andIsSameTracksKeyPathChanges() {
		struct User {
			let id: Int
			let name: String
		}

		let users = [
			User(id: 1, name: "Alice"),
			User(id: 1, name: "Alice Updated"),
			User(id: 2, name: "Bob"),
		]

		var received: [(User, Bool)] = []

		let cancellable = users.publisher
			.andIsSame(\.id)
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		// First emission has no previous, so comparison is arbitrary
		#expect(received[1].1 == true) // id didn't change (1 -> 1)
		#expect(received[2].1 == false) // id changed (1 -> 2)

		cancellable.cancel()
	}

	@Test("andIsSame with strings")
	func andIsSameWithStrings() {
		struct Item {
			let category: String
			let name: String
		}

		let items = [
			Item(category: "A", name: "Item 1"),
			Item(category: "A", name: "Item 2"),
			Item(category: "B", name: "Item 3"),
		]

		var received: [(Item, Bool)] = []

		let cancellable = items.publisher
			.andIsSame(\.category)
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		#expect(received[1].1 == true) // category didn't change (A -> A)
		#expect(received[2].1 == false) // category changed (A -> B)

		cancellable.cancel()
	}

	// MARK: - Chaining Transformations

	@Test("Chaining multiple transformations")
	func chainingMultipleTransformations() {
		let publisher = [1, 2, 3].publisher
		var received: [String] = []

		let cancellable = publisher
			.map { $0 * 2 }
			.value("transformed")
			.any()
			.sink { value in
				received.append(value)
			}

		#expect(received == ["transformed", "transformed", "transformed"])
		cancellable.cancel()
	}

	@Test("withLast and andIsSame combination")
	func withLastAndAndIsSameCombination() {
		struct State {
			let count: Int
		}

		let states = [
			State(count: 1),
			State(count: 1),
			State(count: 2),
		]

		var received: [(State, Bool)] = []

		let cancellable = states.publisher
			.andIsSame(\.count)
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 3)
		#expect(received[1].1 == true) // count same
		#expect(received[2].1 == false) // count changed

		cancellable.cancel()
	}

	// MARK: - Error Handling

	@Test("Transformations preserve error type")
	func transformationsPreserveErrorType() {
		enum TestError: Error { case test }

		let subject = PassthroughSubject<Int, TestError>()
		var errorReceived = false

		let cancellable = subject
			.value("constant")
			.sink(
				receiveCompletion: { completion in
					if case .failure = completion {
						errorReceived = true
					}
				},
				receiveValue: { _ in }
			)

		subject.send(completion: .failure(.test))

		#expect(errorReceived)
		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("withLast with single value")
	func withLastWithSingleValue() {
		let publisher = Just(42)
		var received: [(previous: Int?, current: Int)] = []

		let cancellable = publisher
			.withLast()
			.sink { value in
				received.append(value)
			}

		#expect(received.count == 1)
		#expect(received[0].previous == nil)
		#expect(received[0].current == 42)

		cancellable.cancel()
	}
}
