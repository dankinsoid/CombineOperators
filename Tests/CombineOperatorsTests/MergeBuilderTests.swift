import Combine
@testable import CombineOperators
import Testing

@Suite("MergeBuilder Tests")
struct MergeBuilderTests {

	// MARK: - Basic Merging

	@Test("Merges multiple publishers")
	func mergesMultiplePublishers() async {
		let publisher = AnyPublisher<Int, Never>.merge {
			Just(1)
			Just(2)
			Just(3)
		}

		let expectation = Expectation<Int>(limit: 3)
        let cancellable = publisher.sink {
            expectation.fulfill($0)
        }
		defer { cancellable.cancel() }

        let received = await expectation.values

		#expect(received.sorted() == [1, 2, 3])
	}

	@Test("Merges publishers with different types erased")
	func mergesPublishersWithDifferentTypes() async {
		let publisher = AnyPublisher<String, Never>.merge {
			Just("hello")
			["world", "!"].publisher
			CurrentValueSubject<String, Never>("test")
		}

        let expectation = Expectation<String>(limit: 4)
        let cancellable = publisher.sink { expectation.fulfill($0) }
		defer { cancellable.cancel() }

        let received = await expectation.values

		#expect(Set(received) == ["!", "hello", "test", "world"])
	}

	// MARK: - Single Values and Arrays

	@Test("Single value as publisher")
	func singleValueAsPublisher() async {
		let publisher = AnyPublisher<Int, Never>.merge {
			42
		}

        let expectation = Expectation<Int>(limit: 1)
        let cancellable = publisher.sink { expectation.fulfill($0) }
		defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received == [42])
	}

	@Test("Array as publisher")
	func arrayAsPublisher() async {
		let publisher = AnyPublisher<Int, Never>.merge {
			[1, 2, 3]
		}

        let expectation = Expectation<Int>(limit: 3)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received == [1, 2, 3])
	}

	@Test("Mix of values, arrays, and publishers")
	func mixOfValuesArraysAndPublishers() async {
		let publisher = AnyPublisher<Int, Never>.merge {
			1
			[2, 3]
			Just(4)
		}

        let expectation = Expectation<Int>(limit: 4)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received.sorted() == [1, 2, 3, 4])
	}

	// MARK: - Conditional Merging

	@Test("Conditional if-else true branch")
	func conditionalIfElseTrueBranch() async {
		let condition = true

		let publisher = AnyPublisher<Int, Never>.merge {
			if condition {
				Just(1)
			} else {
				Just(2)
			}
		}

        let expectation = Expectation<Int>(limit: 1)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received == [1])
	}

	@Test("Conditional if-else false branch")
	func conditionalIfElseFalseBranch() async {
		let condition = false

		let publisher = AnyPublisher<Int, Never>.merge {
			if condition {
				Just(1)
			} else {
				Just(2)
			}
		}

        let expectation = Expectation<Int>(limit: 1)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received == [2])
	}

	@Test("Optional publisher present")
	func optionalPublisherPresent() async {
		let optionalValue: Int? = 42

		let publisher = AnyPublisher<Int, Never>.merge {
			if let value = optionalValue {
				Just(value)
			}
			Just(100)
		}

        let expectation = Expectation<Int>(limit: 2)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received.sorted() == [42, 100])
	}

	@Test("Optional publisher absent")
	func optionalPublisherAbsent() async {
		let optionalValue: Int? = nil

		let publisher = AnyPublisher<Int, Never>.merge {
			if let value = optionalValue {
				Just(value)
			}
			Just(100)
		}

        let expectation = Expectation<Int>(limit: 1)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		// Should only receive 100, since optional is nil and creates Empty publisher
		#expect(received == [100])
	}

	// MARK: - Collections

	@Test("Collection of publishers")
	func collectionOfPublishers() async {
		let publishers = [
			Just(1).eraseToAnyPublisher(),
			Just(2).eraseToAnyPublisher(),
			Just(3).eraseToAnyPublisher(),
		]

		let publisher = AnyPublisher<Int, Never>.merge {
			publishers
		}

        let expectation = Expectation<Int>(limit: 3)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received.sorted() == [1, 2, 3])
	}

	// MARK: - Empty and Edge Cases

	@Test("Empty merge block")
	func emptyMergeBlock() async {
		let publisher = AnyPublisher<Int, Never>.merge {
			// Empty block
		}

		var received: [Int] = []
        let expectation = Expectation<Bool>(limit: 1)

		let cancellable = publisher.sink(
            receiveCompletion: { _ in expectation.fulfill(true) },
			receiveValue: { received.append($0) }
		)
		defer { cancellable.cancel() }

        let completed = await expectation.values.first ?? false

		#expect(received == [])
		#expect(completed) // Empty publisher complete immediately
	}

	// MARK: - Error Handling

	@Test("Merge with Error failure type")
	func mergeWithErrorFailureType() async {
		enum TestError: Error { case test }

		let publisher = AnyPublisher<Int, Error>.merge {
			Just(1)
			Just(2).setFailureType(to: Error.self)
			Fail(error: TestError.test)
		}

        let expectation = Expectation<Error>(limit: 1)

		let cancellable = publisher.sink(
			receiveCompletion: {
                if case let .failure(e) = $0 { expectation.fulfill(e) }
			},
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

        let error = await expectation.values.first

		#expect(error != nil)
	}

	@Test("Merge with Never failure type skips failures")
	func mergeWithNeverFailureTypeSkipsFailures() async {
		enum TestError: Error { case test }

		let publisher = AnyPublisher<Int, Never>.merge {
			Just(1)
			Just(2)
			Fail<Int, TestError>(error: .test)
		}

        let expectation = Expectation<Bool>(limit: 1)

		let cancellable = publisher.sink(
            receiveCompletion: { _ in expectation.fulfill(true) },
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

        let completed = await expectation.values.first ?? false

		// Failing publisher is skipped due to skipFailure()
        #expect(completed)
	}

	// MARK: - Complex Scenarios

	@Test("Nested conditionals and arrays")
	func nestedConditionalsAndArrays() async {
		let includeExtra = true
		let multiplier = 2

		let publisher = AnyPublisher<Int, Never>.merge {
			[1, 2]
			if includeExtra {
				[3, 4]
				if multiplier > 1 {
					Just(5)
				}
			}
			6
		}

        let expectation = Expectation<Int>(limit: 6)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received.sorted() == [1, 2, 3, 4, 5, 6])
	}

	@Test("Real-world scenario: merging multiple data sources")
	func realWorldScenarioMergingDataSources() async {
        let cachePublisher = Just("cache").delay(for: .milliseconds(10), scheduler: MainScheduler.instance)
		let networkPublisher = Just("network").delay(for: .milliseconds(20), scheduler: MainScheduler.instance)
		let defaultValue = "default"

		let publisher = AnyPublisher<String, Never>.merge {
			Just(defaultValue)
			cachePublisher
			networkPublisher
		}

        let expectation = Expectation<String>(limit: 3)
        let cancellable = publisher.sink { expectation.fulfill($0) }
        defer { cancellable.cancel() }
        let received = await expectation.values

		#expect(received.count == 3)
		#expect(received.contains("default"))
		#expect(received.contains("cache"))
		#expect(received.contains("network"))
	}
}
