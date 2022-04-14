//
//  Reactive.swift
//  CombineSwift
//
//  Created by Yury Korolev on 5/2/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

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

@available(iOS 13.0, macOS 10.15, *)
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

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: AnyObject {
	
	/// Automatically synthesized binder for a key path between the reactive
	/// base and one of its properties
	public subscript<T>(dynamicMember keyPath: KeyPath<Base, T>) -> ReactiveBinder<Base, T, KeyPath<Base, T>> {
		ReactiveBinder<Base, T, KeyPath<Base, T>>(base, keyPath: keyPath)
	}
	
	public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Base, T>) -> ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>> {
		ReactiveBinder<Base, T, ReferenceWritableKeyPath<Base, T>>(base, keyPath: keyPath)
	}
	
	public func weak<I>(_ method: @escaping (Base) -> (I) -> Void) -> WeakMethod<Base, I> {
		WeakMethod(method, on: base)
	}
	
	public func weak(_ method: @escaping (Base) -> () -> Void) -> WeakMethod<Base, Void> {
		WeakMethod({ base in { _ in method(base)() } }, on: base)
	}
	
	public var asBag: CancellableBag {
		get {
			if let result = objc_getAssociatedObject(base, &cancellableBagKey) as? CancellableBag {
			return result
			}
			let result = CancellableBag()
			objc_setAssociatedObject(base, &cancellableBagKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return result
		}
		nonmutating set {
			objc_setAssociatedObject(base, &cancellableBagKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
}



private var cancellableBagKey = "CancellableBagKey"

/// A type that has reactive extensions.
@available(iOS 13.0, macOS 10.15, *)
public protocol ReactiveCompatible {
    /// Extended type
    associatedtype ReactiveBase

    /// Reactive extensions.
    static var cb: Reactive<ReactiveBase>.Type { get set }

    /// Reactive extensions.
    var cb: Reactive<ReactiveBase> { get set }
}

@available(iOS 13.0, macOS 10.15, *)
extension ReactiveCompatible {
	public typealias It = Self
	
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

import Foundation

/// Extend NSObject with `cb` proxy.
@available(iOS 13.0, macOS 10.15, *)
extension NSObject: ReactiveCompatible {}

public func bag(_ object: Any) -> CancellableBag {
		if let result = objc_getAssociatedObject(object, &cancellableBagKey) as? CancellableBag {
				return result
		}
		let result = CancellableBag()
		objc_setAssociatedObject(object, &cancellableBagKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return result
}

