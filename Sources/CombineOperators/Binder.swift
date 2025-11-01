import Combine
import Foundation

/// Subscriber that binds values to a target object on a specific scheduler.
///
/// Holds a weak reference to target - automatically stops binding when target deallocates.
/// Defaults to main scheduler for UI bindings.
///
/// ```swift
/// let label = UILabel()
/// let binder = Binder(label) { label, text in
///     label.text = text
/// }
/// textPublisher.subscribe(binder)
/// ```
public struct Binder<Input>: Subscriber, @unchecked Sendable {

	public typealias Failure = Never

	private let binding: @Sendable (Input) -> Void
	private weak var _target: (AnyObject & Sendable)?
	public let combineIdentifier = CombineIdentifier()

	/// Creates a binder with custom scheduler.
	///
	/// ```swift
	/// let binder = Binder(model, scheduler: DispatchQueue.global()) { model, value in
	///     model.process(value)
	/// }
	/// ```
	public init<Target: AnyObject & Sendable, S: Scheduler>(
		_ target: Target,
		scheduler: S,
		binding: @escaping (Target, Input) -> Void
	) {
		self.init(target: target) { [weak target] input in
			if let target {
				scheduler.schedule {
					binding(target, input)
				}
			}
		}
	}

	/// Creates a binder that executes on the main actor.
	///
	/// Preferred for UI bindings that require main actor isolation.
	///
	/// ```swift
	/// let button = UIButton()
	/// let binder = Binder(button) { button, isEnabled in
	///     button.isEnabled = isEnabled
	/// }
	/// ```
	public init<Target: AnyObject & Sendable>(
		_ target: Target,
		binding: @escaping @MainActor (Target, Input) -> Void
	) {
		self.init(target, scheduler: MainScheduler.instance) { target, input in
			MainActor.assumeIsolated {
				binding(target, input)
			}
		}
	}

	private init(
		target: (AnyObject & Sendable)?,
		binding: @escaping @Sendable (Input) -> Void
	) {
		self.binding = binding
		_target = target
	}

	public func receive(subscription: Subscription) {
		if let target {
			objc_setAssociatedObject(
				target,
				&deiniterKey,
				Deiniter {
					subscription.cancel()
				},
				.OBJC_ASSOCIATION_RETAIN_NONATOMIC
			)
			subscription.request(.unlimited)
		} else {
			subscription.cancel()
		}
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		if target == nil {
			return .none
		} else {
			binding(input)
			return .unlimited
		}
	}

	public func receive(completion: Subscribers.Completion<Never>) {}

	private final class Deiniter {

		let onDeinit: () -> Void

		init(onDeinit: @escaping () -> Void = {}) {
			self.onDeinit = onDeinit
		}

		deinit {
			onDeinit()
		}
	}

	private var target: (AnyObject & Sendable)? {
		// Since Binder is usually used to bind UI elements on main thread, it's more efficient to use Main thread check instead of lock
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
