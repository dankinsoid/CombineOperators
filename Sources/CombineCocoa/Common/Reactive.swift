import CombineOperators
import Foundation

/// Namespace for reactive extensions via the `cb` property.
///
/// Provides customization point for constrained protocol extensions:
/// ```swift
/// extension Reactive where Base: SomeType {
///     var myProperty: Publisher<Value, Never> { ... }
/// }
/// ```
///
/// Automatically synthesizes binders for writable properties via `@dynamicMemberLookup`:
/// ```swift
/// label.cb.text // Returns ReactiveBinder for label.text
/// publisher.subscribe(label.cb.text) // Binds publisher to label.text
/// ```
@dynamicMemberLookup
public struct Reactive<Base> {
	/// Base object to extend.
	public let base: Base

	/// Creates reactive wrapper around base object.
	public init(_ base: Base) {
		self.base = base
	}
}

extension NSObject: ReactiveCompatible {}

public extension Reactive where Base: AnyObject {

    /// Synthesizes binder for writable property binding via dynamic member lookup.
    ///
    /// Enables reactive binding to object properties:
    /// ```swift
    /// publisher.subscribe(label.cb[\.text]) // Binds publisher output to label.text
    /// ```
    subscript<T>(_ keyPath: ReferenceWritableKeyPath<Base, T>) -> ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>> {
        ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>>(base, keyPath: keyPath)
    }

	/// Synthesizes binder for read-only property access via dynamic member lookup.
	///
	/// ```swift
	/// label.cb.text // Returns ReactiveBinder<UILabel, String?, KeyPath<...>>
	/// ```
    @_disfavoredOverload
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

/// Enables reactive extensions via the `cb` namespace.
///
/// Conform to this protocol to access reactive capabilities:
/// ```swift
/// extension MyType: ReactiveCompatible {}
/// let instance = MyType()
/// instance.cb.someReactiveProperty // Accesses Reactive<MyType> extensions
/// ```
public protocol ReactiveCompatible {
	/// Extended type.
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
