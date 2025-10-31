import Foundation
import Combine

/**
 Observer that enforces interface binding rules:
 * ensures binding is performed on a specific scheduler

 `Binder` doesn't retain target and in case target is released, element isn't bound.
 
 By default it binds elements on main scheduler.
 */
public struct Binder<Input>: Subscriber {

    public typealias Failure = Never

    private let binding: (Input) -> Void
    private weak var _target: AnyObject?
    public let combineIdentifier = CombineIdentifier()

    /// Initializes `Binder`
    ///
    /// - parameter target: Target object.
    /// - parameter scheduler: Scheduler used to bind the events.
    /// - parameter binding: Binding logic.
    public init<Target: AnyObject, S: Scheduler>(
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

    /// Initializes `Binder`
    ///
    /// - parameter target: Target object.
    /// - parameter binding: Binding logic.
    public init<Target: AnyObject>(
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
        target: AnyObject?,
        binding: @escaping (Input) -> Void
    ) {
        self.binding = binding
        self._target = target
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
    
    private var target: AnyObject? {
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
