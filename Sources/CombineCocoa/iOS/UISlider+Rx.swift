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

@available(iOS 13.0, macOS 10.15, *)@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UISlider {
    
    /// Reactive wrapper for `value` property.
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
