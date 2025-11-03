#if os(iOS) || os(tvOS)

import Combine
import CombineOperators
import UIKit


public extension Reactive where Base: UIGestureRecognizer {

	/// Emits gesture recognizer instance on each gesture event.
	///
	/// ```swift
	/// panGesture.cb.event
	///     .sink { recognizer in
	///         let translation = recognizer.translation(in: view)
	///         // Handle gesture
	///     }
	/// ```
	var event: ControlEvent<Base> {
		ControlEvent(
			events: GesturePublisher(base)
		)
	}
}

private struct GesturePublisher<Recognizer: UIGestureRecognizer>: Publisher {

    typealias Output = Recognizer
    typealias Failure = Never

    weak var gestureRecognizer: Recognizer?

    init(_ gestureRecognizer: Recognizer?) {
        self.gestureRecognizer = gestureRecognizer
    }

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Recognizer == S.Input {
        DispatchQueue.ensureRunningOnMainThread()
        let subscriber = AnySubscriber(subscriber)

        let subscription = GestureTarget(gestureRecognizer, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

/// Wraps gesture recognizer target-action pattern for Combine. Must run on main thread.
private final class GestureTarget<Recognizer: UIGestureRecognizer>: CombineTarget, Subscription {
    typealias Callback = (Recognizer) -> Void

    let selector = #selector(ControlTarget.eventHandler(_:))

    weak var gestureRecognizer: Recognizer?
    var subscriber: AnySubscriber<Recognizer, Never>?
    private var demand: Subscribers.Demand = .none

    init(_ gestureRecognizer: Recognizer?, subscriber: AnySubscriber<Recognizer, Never>) {
        self.gestureRecognizer = gestureRecognizer
        self.subscriber = subscriber

        super.init()

        gestureRecognizer?.addTarget(self, action: selector)

        let method = method(for: selector)
        if method == nil {
            #if DEBUG
            fatalError("Can't find method")
            #endif
        }
    }

    func request(_ demand: Subscribers.Demand) {
        MainScheduler.instance.syncSchedule {
            self.demand += demand
        }
    }

    @objc func eventHandler(_ sender: UIGestureRecognizer) {
        if demand > 0, let subscriber, let gestureRecognizer {
            demand -= 1
            demand += subscriber.receive(gestureRecognizer)
        }
    }

    override func cancel() {
        super.cancel()
        MainScheduler.instance.syncSchedule {
            gestureRecognizer?.removeTarget(self, action: selector)
            subscriber = nil
        }
    }
}

#endif
