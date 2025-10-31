//
//  UISwitch+Combine.swift
//  CombineCocoa
//
//  Created by Carlos García on 8/7/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import UIKit
import Combine

extension Reactive where Base: UISwitch {

	/// Bidirectional binding for switch's `isOn` property.
	///
	/// ```swift
	/// toggle.cb.isOn.sink { print("On: \($0)") }
	/// ```
	public var isOn: ControlProperty<Bool> {
        value
    }

	/// Bidirectional binding for switch's `isOn` property (alias for `isOn`).
	///
	/// ⚠️ Versions prior to iOS 10.2 leak `UISwitch` instances - sequence won't complete
	/// when nothing holds a strong reference on those versions.
	public var value: ControlProperty<Bool> {
        return base.cb.controlPropertyWithDefaultEvents(
            getter: { uiSwitch in
                uiSwitch.isOn
            }, setter: { uiSwitch, value in
                uiSwitch.isOn = value
            }
        )
    }

}

#endif
