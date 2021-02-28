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
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIDatePicker {
    /// Reactive wrapper for `date` property.
    public var date: ControlProperty<Date> {
        value
    }

    /// Reactive wrapper for `date` property.
    public var value: ControlProperty<Date> {
        return base.cb.controlPropertyWithDefaultEvents(
            getter: { datePicker in
                datePicker.date
            }, setter: { datePicker, value in
                datePicker.date = value
            }
        )
    }

    /// Reactive wrapper for `countDownDuration` property.
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
