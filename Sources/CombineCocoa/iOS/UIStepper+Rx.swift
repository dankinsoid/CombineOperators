#if os(iOS)

import UIKit
import Combine

extension Reactive where Base: UIStepper {
    
    /// Reactive wrapper for `value` property.
    public var value: ControlProperty<Double> {
        return base.cb.controlPropertyWithDefaultEvents(
            getter: { stepper in
                stepper.value
            }, setter: { stepper, value in
                stepper.value = value
            }
        )
    }
}

#endif

