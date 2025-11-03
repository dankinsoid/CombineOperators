#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UIStepper {
	/// Bidirectional binding for stepper's `value` property.
	///
	/// ```swift
	/// stepper.cb.value.sink { print("Value: \($0)") }
	/// ```
	var value: ControlProperty<Double> {
		controlProperty(
			getter: { stepper in
				stepper.value
			}, setter: { stepper, value in
				stepper.value = value
			}
		)
	}
}

#endif
