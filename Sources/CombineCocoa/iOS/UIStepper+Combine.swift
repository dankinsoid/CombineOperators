#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UIStepper {

	/// Bidirectional binding for stepper's `value` property.
	var value: ControlProperty<Double> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { stepper in
				stepper.value
			}, setter: { stepper, value in
				stepper.value = value
			}
		)
	}
}

#endif
