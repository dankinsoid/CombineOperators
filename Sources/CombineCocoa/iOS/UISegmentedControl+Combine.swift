#if os(iOS) || os(tvOS)

import UIKit
import Combine
extension Reactive where Base: UISegmentedControl {
	/// Bidirectional binding for selected segment index.
	public var selectedSegmentIndex: ControlProperty<Int> {
        base.cb.controlPropertyWithDefaultEvents(
            getter: { segmentedControl in
                segmentedControl.selectedSegmentIndex
            }, setter: { segmentedControl, value in
                segmentedControl.selectedSegmentIndex = value
            }
        )
    }

	/// Binds to enabled state for specific segment.
	public func enabledForSegment(at index: Int) -> Binder<Bool> {
        Binder(self.base) { segmentedControl, segmentEnabled -> Void in
            segmentedControl.setEnabled(segmentEnabled, forSegmentAt: index)
        }
    }

	/// Binds to title for specific segment.
	public func titleForSegment(at index: Int) -> Binder<String?> {
        Binder(self.base) { segmentedControl, title -> Void in
            segmentedControl.setTitle(title, forSegmentAt: index)
        }
    }

	/// Binds to image for specific segment.
	public func imageForSegment(at index: Int) -> Binder<UIImage?> {
        Binder(self.base) { segmentedControl, image -> Void in
            segmentedControl.setImage(image, forSegmentAt: index)
        }
    }
}

#endif
