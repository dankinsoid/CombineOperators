#if os(iOS) || os(tvOS) || os(macOS)

import Combine

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
final class ControlTarget: CombineTarget {
	typealias Callback = (Control) -> Void

	let selector: Selector = #selector(ControlTarget.eventHandler(_:))

	weak var control: Control?
	#if os(iOS) || os(tvOS)
	let controlEvents: UIControl.Event
	#endif
	var callback: Callback?
	#if os(iOS) || os(tvOS)
	init(control: Control, controlEvents: UIControl.Event, callback: @escaping Callback) {
		DispatchQueue.ensureRunningOnMainThread()

		self.control = control
		self.controlEvents = controlEvents
		self.callback = callback

		super.init()

		control.addTarget(self, action: selector, for: controlEvents)

		let method = method(for: selector)
		if method == nil {
			rxFatalError("Can't find method")
		}
	}

	#elseif os(macOS)
	init(control: Control, callback: @escaping Callback) {
		DispatchQueue.ensureRunningOnMainThread()

		self.control = control
		self.callback = callback

		super.init()

		control.target = self
		control.action = selector

		let method = method(for: selector)
		if method == nil {
			rxFatalError("Can't find method")
		}
	}
	#endif

	@objc func eventHandler(_ sender: Control!) {
		if let callback, let control {
			callback(control)
		}
	}

	override func cancel() {
		super.cancel()
		#if os(iOS) || os(tvOS)
		control?.removeTarget(self, action: selector, for: controlEvents)
		#elseif os(macOS)
		control?.target = nil
		control?.action = nil
		#endif
		callback = nil
	}
}

#endif
