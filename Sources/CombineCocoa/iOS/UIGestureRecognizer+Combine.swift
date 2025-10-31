#if os(iOS) || os(tvOS)

import Combine
import UIKit

/// This should be only used from `MainScheduler`
final class GestureTarget<Recognizer: UIGestureRecognizer>: CombineTarget {
	typealias Callback = (Recognizer) -> Void

	let selector = #selector(ControlTarget.eventHandler(_:))

	weak var gestureRecognizer: Recognizer?
	var callback: Callback?

	init(_ gestureRecognizer: Recognizer, callback: @escaping Callback) {
		self.gestureRecognizer = gestureRecognizer
		self.callback = callback

		super.init()

		gestureRecognizer.addTarget(self, action: selector)

		let method = method(for: selector)
		if method == nil {
			#if DEBUG
			fatalError("Can't find method")
			#endif
		}
	}

	@objc func eventHandler(_ sender: UIGestureRecognizer) {
		if let callback, let gestureRecognizer {
			callback(gestureRecognizer)
		}
	}

	override func cancel() {
		super.cancel()
		gestureRecognizer?.removeTarget(self, action: selector)
		callback = nil
	}
}

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
			events: AnyPublisher<Base, Never>.create { [weak control = self.base] observer in
				DispatchQueue.ensureRunningOnMainThread()

				guard let control else {
					observer.receive(completion: .finished)
					return ManualAnyCancellable()
				}

				let observer = GestureTarget(control) { control in
					_ = observer.receive(control)
				}

				return observer
			}
		)
	}
}

#endif
