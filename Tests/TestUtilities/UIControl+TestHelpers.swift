#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

public extension UIControl {

	/// Triggers control events for testing purposes.
	///
	/// `sendActions(for:)` doesn't work reliably in unit tests,
	/// so this manually invokes all target-action pairs.
	func triggerActions(for controlEvents: UIControl.Event) {
		for target in allTargets {
			let actions = actions(forTarget: target, forControlEvent: controlEvents) ?? []
			for actionName in actions {
				let action = Selector(actionName)
				_ = (target as AnyObject).perform(action, with: self)
			}
		}
	}
}

#endif
