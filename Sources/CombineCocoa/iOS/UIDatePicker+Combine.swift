//
//  UIDatePicker+Combine.swift
//  CombineCocoa
//
//  Created by Daniel Tartaglia on 5/31/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import Combine
import UIKit
extension Reactive where Base: UIDatePicker {
	/// Bidirectional binding for date picker's `date` property.
	public var date: ControlProperty<Date> {
        value
    }

	/// Bidirectional binding for date picker's `date` property (alias for `date`).
	public var value: ControlProperty<Date> {
        return base.cb.controlPropertyWithDefaultEvents(
            getter: { datePicker in
                datePicker.date
            }, setter: { datePicker, value in
                datePicker.date = value
            }
        )
    }

	/// Bidirectional binding for countdown duration (timer mode).
	public var countDownDuration: ControlProperty<TimeInterval> {
        return base.cb.controlPropertyWithDefaultEvents(
            getter: { datePicker in
                datePicker.countDownDuration
            }, setter: { datePicker, value in
                datePicker.countDownDuration = value
            }
        )
    }
}

#endif
