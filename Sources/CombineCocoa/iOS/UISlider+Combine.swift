#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UISlider {

	/// Bidirectional binding for slider's `value` property.
	///
	/// ```swift
	/// slider.cb.value
	///     .sink { print("Value: \($0)") }
	///
	/// publisher.subscribe(slider.cb.value) // Bind to slider
	/// ```
	var value: ControlProperty<Float> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { slider in
				slider.value
			}, setter: { slider, value in
				slider.value = value
			}
		)
	}
}

#endif
