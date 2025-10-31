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
		let source = lazyInstanceAnyPublisher(&rx_tap_key) { () -> AnyPublisher<Void, Error> in
			.create { [weak control = self.base] observer in
				guard let control else {
					observer.receive(completion: .finished)
					return ManualAnyCancellable()
				}
				let target = BarButtonItemTarget(barButtonItem: control) {
					_ = observer.receive()
				}
				return target
			}
			.prefix(untilOutputFrom: self.deallocated)
			.share()
			.eraseToAnyPublisher()
		}
		return ControlEvent(events: source)
	}
}

@objc
final class BarButtonItemTarget: CombineTarget {
	typealias Callback = () -> Void

	weak var barButtonItem: UIBarButtonItem?
	var callback: Callback!

	init(barButtonItem: UIBarButtonItem, callback: @escaping () -> Void) {
		self.barButtonItem = barButtonItem
		self.callback = callback
		super.init()
		barButtonItem.target = self
		barButtonItem.action = #selector(BarButtonItemTarget.action(_:))
	}

	override func cancel() {
		super.cancel()
		#if DEBUG
		DispatchQueue.ensureRunningOnMainThread()
		#endif

		barButtonItem?.target = nil
		barButtonItem?.action = nil

		callback = nil
	}

	@objc func action(_ sender: AnyObject) {
		callback()
	}
}

#endif
