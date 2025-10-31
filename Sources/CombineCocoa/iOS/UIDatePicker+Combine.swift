#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UIDatePicker {
	/// Bidirectional binding for date picker's `date` property.
	///
	/// ```swift
	/// datePicker.cb.date.sink { print("Date: \($0)") }
	/// ```
	var date: ControlProperty<Date> {
		value
	}

	/// Bidirectional binding for date picker's `date` property (alias for `date`).
	var value: ControlProperty<Date> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { datePicker in
				datePicker.date
			}, setter: { datePicker, value in
				datePicker.date = value
			}
		)
	}

	/// Bidirectional binding for countdown duration (timer mode).
	var countDownDuration: ControlProperty<TimeInterval> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { datePicker in
				datePicker.countDownDuration
			}, setter: { datePicker, value in
				datePicker.countDownDuration = value
			}
		)
	}
}

#endif
