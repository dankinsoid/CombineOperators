import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
@dynamicMemberLookup
public final class ReactiveBinder<Target: AnyObject, Input, KP: KeyPath<Target, Input>>: CustomCombineIdentifierConvertible {
	
	fileprivate weak var target: Target?
	fileprivate let keyPath: KP
    
    public var combineIdentifier: CombineIdentifier {
        target.map(CombineIdentifier.init) ?? CombineIdentifier()
    }
	
	public init(_ target: Target?, keyPath: KP) {
		self.target = target
		self.keyPath = keyPath
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Input, T>) -> ReactiveBinder<Target, T, KeyPath<Target, T>> {
		ReactiveBinder<Target, T, KeyPath<Target, T>>(target, keyPath: self.keyPath.appending(path: keyPath))
	}
	
	public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Input, T>) -> ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>> {
		ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>>(target, keyPath: self.keyPath.append(reference: keyPath))
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension ReactiveBinder: Subscriber where KP: ReferenceWritableKeyPath<Target, Input> {
	public typealias Failure = Never
	
	public func receive(subscription: Subscription) {
		subscription.request(.unlimited)
	}
	
	public func receive(_ input: Input) -> Subscribers.Demand {
		RunLoop.main.schedule {
			if let target = self.target {
				target[keyPath: self.keyPath] = input
			}
		}
		return .unlimited
	}
	
	public func receive(completion: Subscribers.Completion<Never>) {}
	
	public subscript<T>(dynamicMember keyPath: WritableKeyPath<Input, T>) -> ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>> {
		ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>>(target, keyPath: self.keyPath.append(writable: keyPath))
	}
	
}

extension KeyPath {
	
	func append<T>(reference: ReferenceWritableKeyPath<Value, T>) -> ReferenceWritableKeyPath<Root, T> {
		appending(path: reference)
	}
	
}

extension ReferenceWritableKeyPath {
	
	func append<T>(writable: WritableKeyPath<Value, T>) -> ReferenceWritableKeyPath<Root, T> {
		appending(path: writable)
	}
	
}
