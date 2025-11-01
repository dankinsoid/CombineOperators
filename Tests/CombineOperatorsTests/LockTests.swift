import Combine
@testable import CombineOperators
import Foundation
import Testing

@Suite("Lock Tests")
struct LockTests {

	// MARK: - Basic Lock Functionality

	@Test("Lock basic locking and unlocking")
	func lockBasicLockingAndUnlocking() {
		let lock = Lock()
		lock.lock()
		lock.unlock()
		#expect(true) // If we get here, no deadlock occurred
	}

	@Test("Lock withLock executes action")
	func lockWithLockExecutesAction() {
		let lock = Lock()
		var executed = false

		lock.withLock {
			executed = true
		}

		#expect(executed)
	}

	@Test("Lock withLock returns value")
	func lockWithLockReturnsValue() {
		let lock = Lock()
		let result = lock.withLock { 42 }
		#expect(result == 42)
	}

	@Test("Lock withLock propagates errors")
	func lockWithLockPropagatesErrors() {
		enum TestError: Error { case test }

		let lock = Lock()
		#expect(throws: TestError.self) {
			try lock.withLock {
				throw TestError.test
			}
		}
	}

	// MARK: - Thread Safety

	@Test("Lock protects concurrent access")
	func lockProtectsConcurrentAccess() async {
		let lock = Lock()
		var counter = 0
		let iterations = 1000

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< iterations {
				group.addTask {
					lock.withLock {
						counter += 1
					}
				}
			}
			await group.waitForAll()
		}

		#expect(counter == iterations)
	}

	@Test("Lock prevents race conditions")
	func lockPreventsRaceConditions() async {
		let lock = Lock()
		var array: [Int] = []
		let iterations = 100

		await withTaskGroup(of: Void.self) { group in
			for i in 0 ..< iterations {
				group.addTask {
					lock.withLock {
						array.append(i)
					}
				}
			}
			await group.waitForAll()
		}

		#expect(array.count == iterations)
	}

	// MARK: - @Locked Property Wrapper

	@Test("Locked wraps value correctly")
	func lockedWrapsValueCorrectly() {
		@Locked var value = 42
		#expect(value == 42)
	}

	@Test("Locked allows value mutation")
	func lockedAllowsValueMutation() {
		@Locked var counter = 0
		counter += 1
		#expect(counter == 1)
	}

	@Test("Locked init with wrappedValue")
	func lockedInitWithWrappedValue() {
		let locked = Locked(wrappedValue: "test")
		#expect(locked.wrappedValue == "test")
	}

	@Test("Locked init with value directly")
	func lockedInitWithValueDirectly() {
		let locked = Locked("test")
		#expect(locked.wrappedValue == "test")
	}

	@Test("Locked withLock provides exclusive access")
	func lockedWithLockProvidesExclusiveAccess() {
		let locked = Locked(0)
		let result = locked.withLock { value in
			value += 1
			return value
		}
		#expect(result == 1)
		#expect(locked.wrappedValue == 1)
	}

	@Test("Locked withLock can modify value")
	func lockedWithLockCanModifyValue() {
		let locked = Locked([1, 2, 3])
		locked.withLock { array in
			array.append(4)
		}
		#expect(locked.wrappedValue == [1, 2, 3, 4])
	}

	// MARK: - Thread Safety with @Locked

	@Test("Locked protects concurrent read/write")
	func lockedProtectsConcurrentReadWrite() async {
		let counter = Locked(0)
		let iterations = 1000

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< iterations {
				group.addTask {
                    counter.wrappedValue += 1
				}
			}
			await group.waitForAll()
		}

        #expect(counter.wrappedValue == iterations)
	}

	@Test("Locked prevents race conditions in array")
	func lockedPreventsRaceConditionsInArray() async {
		let locked = Locked<[Int]>([])
		let iterations = 100

		await withTaskGroup(of: Void.self) { group in
			for i in 0 ..< iterations {
				group.addTask {
					locked.withLock { array in
						array.append(i)
					}
				}
			}
			await group.waitForAll()
		}

		#expect(locked.wrappedValue.count == iterations)
	}

	@Test("Locked concurrent reads are safe")
	func lockedConcurrentReadsAreSafe() async {
		let locked = Locked(42)
		var readValues: [Int] = []
		let lock = Lock()

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< 100 {
				group.addTask {
					let value = locked.wrappedValue
					lock.withLock {
						readValues.append(value)
					}
				}
			}
			await group.waitForAll()
		}

		#expect(readValues.allSatisfy { $0 == 42 })
		#expect(readValues.count == 100)
	}

	// MARK: - Optional Value Initialization

	@Test("Locked init with nil for optional types")
	func lockedInitWithNilForOptionalTypes() {
		let locked = Locked<String?>()
		#expect(locked.wrappedValue == nil)
	}

	// MARK: - Complex Data Structures

	@Test("Locked with dictionary operations")
	func lockedWithDictionaryOperations() async {
		let locked = Locked<[String: Int]>([:])

		await withTaskGroup(of: Void.self) { group in
			for i in 0 ..< 100 {
				group.addTask {
					locked.withLock { dict in
						dict["key_\(i)"] = i
					}
				}
			}
			await group.waitForAll()
		}

		#expect(locked.wrappedValue.count == 100)
	}

	@Test("Locked with struct modification")
	func lockedWithStructModification() {
		struct Counter {
			var value = 0
		}

		let locked = Locked(Counter())
		locked.withLock { counter in
			counter.value += 1
		}

		#expect(locked.wrappedValue.value == 1)
	}
}
