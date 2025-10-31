#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UISwitch {

	/// Bidirectional binding for switch's `isOn` property.
	///
	/// ```swift
	/// toggle.cb.isOn.sink { print("On: \($0)") }
	/// ```
	var isOn: ControlProperty<Bool> {
		value
	}

	/// Bidirectional binding for switch's `isOn` property (alias for `isOn`).
	///
	/// ⚠️ Versions prior to iOS 10.2 leak `UISwitch` instances - sequence won't complete
	/// when nothing holds a strong reference on those versions.
	var value: ControlProperty<Bool> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { uiSwitch in
				uiSwitch.isOn
			}, setter: { uiSwitch, value in
				uiSwitch.isOn = value
			}
		)
	}
}

#endif
