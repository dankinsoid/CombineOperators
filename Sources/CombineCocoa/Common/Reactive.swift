/* 
 Use `Reactive` proxy as customization point for constrained protocol extensions.

 General pattern would be:

 // 1. Extend Reactive protocol with constrain on Base
 // Read as: Reactive Extension where Base is a SomeType
 extension Reactive where Base: SomeType {
 // 2. Put any specific reactive extension for SomeType here
 }

 With this approach we can have more specialized methods and properties using
 `Base` and not just specialized on common base type.

 `Binder`s are also automatically synthesized using `@dynamicMemberLookup` for writable reference properties of the reactive base.
 */

import CombineOperators

@dynamicMemberLookup
public struct Reactive<Base> {

	/// Base object to extend.
	public let base: Base

	/// Creates extensions with base object.
	///
	/// - parameter base: Base object.
	public init(_ base: Base) {
		self.base = base
	}
}

public extension Reactive where Base: AnyObject {

	/// Synthesizes binder for read-only property access via dynamic member lookup.
	///
	/// ```swift
	/// label.cb.text // Returns ReactiveBinder<UILabel, String?, KeyPath<...>>
	/// ```
	subscript<T>(dynamicMember keyPath: KeyPath<Base, T>) -> ReactiveBinder<Base, T, KeyPath<Base, T>> {
		ReactiveBinder<Base, T, KeyPath<Base, T>>(base, keyPath: keyPath)
	}

	/// Synthesizes binder for writable property binding via dynamic member lookup.
	///
	/// Enables reactive binding to object properties:
	/// ```swift
	/// publisher.subscribe(label.cb.text) // Binds publisher output to label.text
	/// ```
	subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, T>) -> ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>> {
		ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>>(base, keyPath: keyPath)
	}
}

/// Protocol enabling reactive extensions via the `cb` namespace.
///
/// Conform to this protocol to add reactive capabilities to your types.
public protocol ReactiveCompatible {

	/// Extended type
	associatedtype ReactiveBase

	/// Reactive extensions namespace (type-level).
	static var cb: Reactive<ReactiveBase>.Type { get set }

	/// Reactive extensions namespace (instance-level).
	var cb: Reactive<ReactiveBase> { get set }
}

public extension ReactiveCompatible {

	/// Reactive extensions.
	static var cb: Reactive<Self>.Type {
		get { Reactive<Self>.self }
		// this enables using Reactive to "mutate" base type
		// swiftlint:disable:next unused_setter_value
		set {}
	}

	/// Reactive extensions.
	var cb: Reactive<Self> {
		get { Reactive(self) }
		// this enables using Reactive to "mutate" base object
		// swiftlint:disable:next unused_setter_value
		set {}
	}
}
