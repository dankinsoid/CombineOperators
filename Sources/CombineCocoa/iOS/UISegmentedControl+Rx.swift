#if os(iOS) || os(tvOS)

import UIKit
import Combine
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UISegmentedControl {
    /// Reactive wrapper for `selectedSegmentIndex` property.
    public var selectedSegmentIndex: ControlProperty<Int> {
        base.cb.controlPropertyWithDefaultEvents(
            getter: { segmentedControl in
                segmentedControl.selectedSegmentIndex
            }, setter: { segmentedControl, value in
                segmentedControl.selectedSegmentIndex = value
            }
        )
    }
    
    /// Reactive wrapper for `setEnabled(_:forSegmentAt:)`
    public func enabledForSegment(at index: Int) -> Binder<Bool> {
        Binder(self.base) { segmentedControl, segmentEnabled -> Void in
            segmentedControl.setEnabled(segmentEnabled, forSegmentAt: index)
        }
    }
    
    /// Reactive wrapper for `setTitle(_:forSegmentAt:)`
    public func titleForSegment(at index: Int) -> Binder<String?> {
        Binder(self.base) { segmentedControl, title -> Void in
            segmentedControl.setTitle(title, forSegmentAt: index)
        }
    }
    
    /// Reactive wrapper for `setImage(_:forSegmentAt:)`
    public func imageForSegment(at index: Int) -> Binder<UIImage?> {
        Binder(self.base) { segmentedControl, image -> Void in
            segmentedControl.setImage(image, forSegmentAt: index)
        }
    }
}

#endif
