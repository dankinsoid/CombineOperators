#if os(iOS) || os(tvOS)

import Combine
import CombineOperators
import UIKit

private var rx_tap_key: UInt8 = 0
public extension Reactive where Base: UIBarButtonItem {

	/// Emits when bar button item is tapped.
	///
	/// ```swift
	/// barButton.cb.tap.sink { print("Tapped") }
	/// ```
    var tap: ControlEvent<Void> {
        let source = lazyInstanceAnyPublisher(&rx_tap_key) { () -> AnyPublisher<Void, Never> in
            BarButtonItemTapPublisher(barButtonItem: base)
                .prefix(untilOutputFrom: onDeinit)
                .share()
                .eraseToAnyPublisher()
        }
        return ControlEvent(events: source)
    }
}

private struct BarButtonItemTapPublisher: Publisher {
    
    typealias Output = Void
    typealias Failure = Never
    
    weak var barButtonItem: UIBarButtonItem?

    func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        let subscriber = AnySubscriber(subscriber)
        let subscription = BarButtonItemTarget(barButtonItem: barButtonItem, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

@objc
private final class BarButtonItemTarget: CombineTarget, Subscription {

	weak var barButtonItem: UIBarButtonItem?
    var subscriber: AnySubscriber<Void, Never>?
    var demand: Subscribers.Demand = .none

    init(barButtonItem: UIBarButtonItem?, subscriber: AnySubscriber<Void, Never>) {
		self.barButtonItem = barButtonItem
        self.subscriber = subscriber
		super.init()
		barButtonItem?.target = self
		barButtonItem?.action = #selector(BarButtonItemTarget.action(_:))
	}

	override func cancel() {
		super.cancel()
        MainScheduler.instance.syncSchedule {
            barButtonItem?.target = nil
            barButtonItem?.action = nil
            subscriber = nil
        }
	}

    func request(_ demand: Subscribers.Demand) {
        MainScheduler.instance.syncSchedule {
            self.demand += demand
        }
    }

	@objc func action(_ sender: AnyObject) {
        guard demand > 0, let subscriber else {
            return
        }
        demand -= 1
        demand += subscriber.receive()
	}
}

#endif
