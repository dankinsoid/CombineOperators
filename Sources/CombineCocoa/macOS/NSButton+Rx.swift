//
//  NSButton+Combine.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 5/17/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(macOS)

import Combine
import Cocoa
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: NSButton {
    
    /// Reactive wrapper for control event.
    public var tap: ControlEvent<Void> {
        self.controlEvent
    }
    
    /// Reactive wrapper for `state` property`.
    public var state: ControlProperty<NSControl.StateValue> {
        return self.base.cb.controlProperty(
            getter: { control in
                return control.state
            }, setter: { (control: NSButton, state: NSControl.StateValue) in
                control.state = state
            }
        )
    }
}

#endif
