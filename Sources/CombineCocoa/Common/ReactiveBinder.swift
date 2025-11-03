import Combine
import CombineOperators
import Foundation

/// Binds publisher values to target object properties via keypaths.
///
/// Weakly holds target and schedules updates on main thread. Automatically cancels
/// subscription when target deallocates.
///
/// ```swift
/// let label = UILabel()
/// publisher.subscribe(label.cb.text) // Updates label.text on main thread
/// ```
@dynamicMemberLookup
public final class ReactiveBinder<Target: AnyObject, Input, KP: KeyPath<Target, Input>>: CustomCombineIdentifierConvertible, @unchecked Sendable {

	fileprivate weak var _target: Target?
	fileprivate let keyPath: KP
    fileprivate var deinitCancellable: AnyCancellable?

	private init(
		target: Target?,
		keyPath: KP
	) {
		self._target = target
		self.keyPath = keyPath
	}

	public convenience init(_ target: Target, keyPath: KP) {
		self.init(target: target, keyPath: keyPath)
	}

	/// Chains read-only keypath for nested property access.
	public subscript<T>(dynamicMember keyPath: KeyPath<Input, T>) -> ReactiveBinder<Target, T, KeyPath<Target, T>> {
        ReactiveBinder<Target, T, KeyPath<Target, T>>(
            target: target,
            keyPath: self.keyPath.appending(path: keyPath)
        )
	}

    /// Chains writable keypath for nested property binding.
    ///
    /// ```swift
    /// publisher.subscribe(view.cb.layer.opacity) // Binds to view.layer.opacity
    /// ```
    public subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Input, T>) -> ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>> {
        ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>>(
            target: target,
            keyPath: self.keyPath.append(reference: keyPath)
        )
    }

	private var target: Target? {
		// Since ReactiveBinder is used to bind UI elements on main thread, it's more efficient to use Main thread check instead of lock
		if Thread.isMainThread {
			return _target
		} else {
			return DispatchQueue.main.sync {
				_target
			}
		}
	}
}

private var deiniterKey = 0

extension ReactiveBinder: Subscriber where KP: ReferenceWritableKeyPath<Target, Input> {

	public typealias Failure = Never

	/// Starts subscription, cancels automatically when target deallocates.
	public func receive(subscription: Subscription) {
		if let target {
            let cancellable = onDeinit(of: target, perform: subscription.cancel)
            MainScheduler.instance.syncSchedule {
                deinitCancellable = cancellable
            }
			subscription.request(.unlimited)
		} else {
			subscription.cancel()
		}
	}

	/// Receives value and updates target property on main thread.
	public func receive(_ input: Input) -> Subscribers.Demand {
        MainScheduler.instance.syncSchedule {
            if let target = _target {
                target[keyPath: keyPath] = input
                return .unlimited
            } else {
                return .none
            }
        }
	}

	public func receive(completion: Subscribers.Completion<Never>) {
        MainScheduler.instance.syncSchedule {
            _target = nil
            deinitCancellable = nil
        }
    }

    @_disfavoredOverload
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Input, T>) -> ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>> {
        ReactiveBinder<Target, T, ReferenceWritableKeyPath<Target, T>>(
            target: target,
            keyPath: self.keyPath.append(writable: keyPath)
        )
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
