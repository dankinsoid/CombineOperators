import Combine
@testable import CombineOperators
import Testing

@Suite("Publisher Extensions Tests")
struct PublisherExtensionsTests {

	// MARK: - share(replay:)

	@Test("Share with replay 0 doesn't replay")
	func shareWithReplayZero() async {
		var computeCount = 0
		let publisher = Deferred {
			Future<Int, Never> { promise in
				computeCount += 1
				promise(.success(42))
			}
		}
		.share(replay: 0)

		var values1: [Int] = []
		let c1 = publisher.sink { values1.append($0) }
		defer { c1.cancel() }

		try? await Task.sleep(nanoseconds: 50_000_000)

		var values2: [Int] = []
		let c2 = publisher.sink { values2.append($0) }
		defer { c2.cancel() }

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(values1 == [42])
		#expect(values2 == []) // No replay
		#expect(computeCount == 1) // Shared
	}

	@Test("Share with replay 1 replays last value")
	func shareWithReplayOne() async {
		let subject = PassthroughSubject<Int, Never>()
		let shared = subject.share(replay: 1)

		var values1: [Int] = []
		let c1 = shared.sink { values1.append($0) }
		defer { c1.cancel() }

		subject.send(1)
		subject.send(2)

		try? await Task.sleep(nanoseconds: 50_000_000)

		var values2: [Int] = []
		let c2 = shared.sink { values2.append($0) }
		defer { c2.cancel() }

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(values1 == [1, 2])
		#expect(values2 == [2]) // Replays last
	}

	@Test("Share with replay N replays N values")
	func shareWithReplayN() async {
		let subject = PassthroughSubject<Int, Never>()
		let shared = subject.share(replay: 3)

		var values1: [Int] = []
		let c1 = shared.sink { values1.append($0) }
		defer { c1.cancel() }

		for i in 1 ... 5 {
			subject.send(i)
		}

		try? await Task.sleep(nanoseconds: 50_000_000)

		var values2: [Int] = []
		let c2 = shared.sink { values2.append($0) }
		defer { c2.cancel() }

		try? await Task.sleep(nanoseconds: 50_000_000)

		#expect(values1 == [1, 2, 3, 4, 5])
		#expect(values2 == [3, 4, 5]) // Replays last 3
	}

	// MARK: - Weak Reference

	@Test("Weak reference breaks retain cycle")
	func weakReferenceBreaksRetainCycle() {
		class TestObject {
			var cancellable: AnyCancellable?
			var value = 0

			func bind() {
				cancellable = Just(42)
					.with(weak: self)
					.sink { object, value in
						object.value = value
					}
			}
		}

		weak var weakRef: TestObject?

		do {
			let object = TestObject()
			weakRef = object
			object.bind()
			#expect(object.value == 42)
		}

		#expect(weakRef == nil) // Object deallocated
	}

	// MARK: - Error Handling

	@Test("Catch error recovery")
	func catchErrorRecovery() {
		enum TestError: Error { case test }

		let publisher = Fail<Int, TestError>(error: .test)
			.catch { _ in Just(42) }

		var received: [Int] = []
		let cancellable = publisher.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [42])
	}

	@Test("Replaces error with default value")
	func replacesErrorWithDefaultValue() {
		enum TestError: Error { case test }

		let publisher = Fail<Int, TestError>(error: .test)
			.replaceError(with: 999)

		var received: [Int] = []
		let cancellable = publisher.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [999])
	}

	// MARK: - Optional

	@Test("Filter nil removes nils")
	func filterNilRemovesNils() {
		let values: [Int?] = [1, nil, 2, nil, 3]
		let publisher = values.publisher

		var received: [Int] = []
		let cancellable = publisher
			.skipNil()
			.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [1, 2, 3])
	}

	@Test("Replace nil with default")
	func replaceNilWithDefault() {
		let values: [Int?] = [1, nil, 2, nil, 3]
		let publisher = values.publisher

		var received: [Int] = []
		let cancellable = publisher
			.replaceNil(with: 0)
			.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [1, 0, 2, 0, 3])
	}

	// MARK: - Transformations

	@Test("Map to value")
	func mapToValue() {
		let publisher = Just(())

		var received: [Int] = []
		let cancellable = publisher
			.map { 42 }
			.sink { received.append($0) }
		defer { cancellable.cancel() }

		#expect(received == [42])
	}

	@Test("Map to void")
	func mapToVoid() {
		let publisher = Just(42)

		var voidReceived = false
		let cancellable = publisher
			.void
			.sink { _ in voidReceived = true }
		defer { cancellable.cancel() }

		#expect(voidReceived)
	}

	// MARK: - Events

	@Test("On value handler")
	func onValueHandler() {
		var capturedValue: Int?

		let publisher = Just(42)
			.onValue { capturedValue = $0 }

		let cancellable = publisher.sink { _ in }
		defer { cancellable.cancel() }

		#expect(capturedValue == 42)
	}

	@Test("On error handler")
	func onErrorHandler() {
		enum TestError: Error { case test }
		var capturedError: TestError?

		let publisher = Fail<Int, TestError>(error: .test)
			.onFailure { capturedError = $0 }

		let cancellable = publisher.sink(
			receiveCompletion: { _ in },
			receiveValue: { _ in }
		)
		defer { cancellable.cancel() }

		#expect(capturedError != nil)
	}

	@Test("On completed handler")
	func onCompletedHandler() {
		var didComplete = false

		let publisher = Just(42)
			.onFinished { didComplete = true }

		let cancellable = publisher.sink { _ in }
		defer { cancellable.cancel() }

		#expect(didComplete)
	}
}
