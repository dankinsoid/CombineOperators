#if os(iOS) || os(tvOS) || os(macOS)

import Combine
import CombineOperators

#if os(iOS) || os(tvOS)
import UIKit

typealias Control = UIKit.UIControl
#elseif os(macOS)
import Cocoa

typealias Control = Cocoa.NSControl
#endif

/// Wraps UIControl/NSControl target-action pattern for Combine integration.
///
/// Must be used from `MainScheduler`. Automatically removes target on cancellation.
final class ControlTarget<C: Control>: CombineTarget, Subscription {
    
	typealias Callback = (C) -> Void

	let selector: Selector = #selector(ControlTarget.eventHandler(_:))

	weak var control: C?
    private var demand: Subscribers.Demand = .none
	#if os(iOS) || os(tvOS)
	let controlEvents: UIControl.Event
	#endif
	var subscriber: AnySubscriber<C, Never>?
	#if os(iOS) || os(tvOS)
    init(control: C?, controlEvents: UIControl.Event, subscriber: AnySubscriber<C, Never>) {
		DispatchQueue.ensureRunningOnMainThread()

		self.control = control
		self.controlEvents = controlEvents
        self.subscriber = subscriber

		super.init()

		control?.addTarget(self, action: selector, for: controlEvents)

		let method = method(for: selector)
		if method == nil {
			rxFatalError("Can't find method")
		}
	}

	#elseif os(macOS)
	init(control: C?, subscriber: AnySubscriber<C, Never>) {
		DispatchQueue.ensureRunningOnMainThread()

		self.control = control
		self.subscriber = subscriber

		super.init()

		control?.target = self
		control?.action = selector

		let method = method(for: selector)
		if method == nil {
			rxFatalError("Can't find method")
		}
	}
	#endif

	@objc func eventHandler(_ sender: Control!) {
        if let subscriber, let control, demand > .none {
            demand -= 1
            demand += subscriber.receive(control)
		}
	}

    func request(_ demand: Subscribers.Demand) {
        MainScheduler.instance.syncSchedule {
            self.demand += demand
        }
    }

	override func cancel() {
		super.cancel()
        MainScheduler.instance.syncSchedule {
#if os(iOS) || os(tvOS)
            control?.removeTarget(self, action: selector, for: controlEvents)
#elseif os(macOS)
            control?.target = nil
            control?.action = nil
#endif
            subscriber = nil
        }
	}
}

#if os(iOS) || os(tvOS)
struct ControlPublisher<Output: Control>: Publisher {

    typealias Failure = Never

    weak var control: Output?
    let events: UIControl.Event

    init(control: Output?, events: UIControl.Event) {
        self.control = control
        self.events = events
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        let subscriber = AnySubscriber(subscriber)
        let subscription = ControlTarget(control: control, controlEvents: events, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
#endif

#if os(macOS)
struct ControlPublisher<Output: Control>: Publisher {

    typealias Failure = Never

    weak var control: Output?

    init(control: Output?) {
        self.control = control
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
        let subscriber = AnySubscriber(subscriber)
        let subscription = ControlTarget(control: control, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}
#endif

#endif
