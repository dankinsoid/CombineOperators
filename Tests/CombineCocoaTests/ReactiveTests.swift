import Combine
@testable import CombineCocoa
import Foundation
import Testing

@Suite("Reactive Wrapper Tests")
struct ReactiveTests {

	// MARK: - Basic Functionality

	@Test("Creates reactive wrapper")
	func createsReactiveWrapper() {
		let object = NSObject()
		let reactive = Reactive(object)

		#expect(reactive.base === object)
	}

	@Test("Accessor via cb property")
	func accessorViaCbProperty() {
		let object = NSObject()
		let reactive = object.cb

		#expect(reactive.base === object)
	}

	// MARK: - Identity

	@Test("Reactive wrapper identity")
	func reactiveWrapperIdentity() {
		let object = NSObject()
		let reactive1 = object.cb
		let reactive2 = object.cb

		// Both wrappers should reference the same base object
		#expect(reactive1.base === reactive2.base)
	}

	// MARK: - Custom Types

	@Test("Works with custom classes")
	func worksWithCustomClasses() {
        final class CustomClass: ReactiveCompatible {}

		let custom = CustomClass()
		let reactive = custom.cb

		#expect(reactive.base === custom)
	}

	// MARK: - Protocol Extensions

	@Test("Reactive wrapper conforms to ReactiveCompatible")
	func reactiveWrapperConformsToReactiveCompatible() {
		let object = NSObject()

		// If this compiles, the protocol is properly implemented
		func requiresReactiveCompatible<T: ReactiveCompatible>(_ value: T) -> Reactive<T> {
			value.cb
		}

		let reactive = requiresReactiveCompatible(object)
		#expect(reactive.base === object)
	}

	// MARK: - Thread Safety

	@Test("Thread-safe access to base")
	func threadSafeAccessToBase() async {
		let object = NSObject()
		let reactive = object.cb

		await withTaskGroup(of: Bool.self) { group in
			for _ in 0..<100 {
				group.addTask {
					reactive.base === object
				}
			}

			for await result in group {
				#expect(result)
			}
		}
	}

	// MARK: - Memory Management

	@Test("Does not retain base object")
	func doesNotRetainBaseObject() {
		weak var weakObject: NSObject?

		do {
			let object = NSObject()
			weakObject = object
			_ = object.cb
		}

		// Object should be deallocated since Reactive doesn't retain it
		#expect(weakObject == nil)
	}

	@Test("Multiple reactive wrappers don't affect retention")
	func multipleReactiveWrappersDontAffectRetention() {
		weak var weakObject: NSObject?

		do {
			let object = NSObject()
			weakObject = object
			_ = object.cb
			_ = object.cb
			_ = object.cb
		}

		#expect(weakObject == nil)
	}

	// MARK: - Type Preservation

	@Test("Preserves base type information")
	func preservesBaseTypeInformation() {
        final class SpecificClass: ReactiveCompatible {
			let value = 42
		}

		let specific = SpecificClass()
		let reactive = specific.cb

		// Should preserve type information
		#expect(reactive.base.value == 42)
	}
}
