//
//  UISlider+Combine.swift
//  CombineCocoa
//
//  Created by Alexander van der Werff on 28/05/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import Combine
import UIKit

extension Reactive where Base: UISlider {

	/// Bidirectional binding for slider's `value` property.
	///
	/// ```swift
	/// slider.cb.value
	///     .sink { print("Value: \($0)") }
	///
	/// publisher.subscribe(slider.cb.value) // Bind to slider
	/// ```
	public var value: ControlProperty<Float> {
        return base.cb.controlPropertyWithDefaultEvents(
            getter: { slider in
                slider.value
            }, setter: { slider, value in
                slider.value = value
            }
        )
    }

}

#endif
