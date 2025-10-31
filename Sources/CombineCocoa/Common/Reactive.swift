/**
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

extension Reactive where Base: AnyObject {
	
	/// Automatically synthesized binder for a key path between the reactive
	/// base and one of its properties
	public subscript<T>(dynamicMember keyPath: KeyPath<Base, T>) -> ReactiveBinder<Base, T, KeyPath<Base, T>> {
		ReactiveBinder<Base, T, KeyPath<Base, T>>(base, keyPath: keyPath)
	}
	
	public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, T>) -> ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>> {
		ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>>(base, keyPath: keyPath)
	}
}

/// A type that has reactive extensions.
public protocol ReactiveCompatible {

    /// Extended type
    associatedtype ReactiveBase

    /// Reactive extensions.
    static var cb: Reactive<ReactiveBase>.Type { get set }

    /// Reactive extensions.
    var cb: Reactive<ReactiveBase> { get set }
}

extension ReactiveCompatible {

    /// Reactive extensions.
    public static var cb: Reactive<Self>.Type {
        get { Reactive<Self>.self }
        // this enables using Reactive to "mutate" base type
        // swiftlint:disable:next unused_setter_value
        set { }
    }

    /// Reactive extensions.
    public var cb: Reactive<Self> {
        get { Reactive(self) }
        // this enables using Reactive to "mutate" base object
        // swiftlint:disable:next unused_setter_value
        set { }
    }
}
