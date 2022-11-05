#if os(iOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)@available(iOS 13.0, macOS 10.15, *)
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

