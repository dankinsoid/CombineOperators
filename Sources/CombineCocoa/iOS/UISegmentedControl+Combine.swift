#if os(iOS) || os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UISegmentedControl {
	/// Bidirectional binding for selected segment index.
	var selectedSegmentIndex: ControlProperty<Int> {
		base.cb.controlPropertyWithDefaultEvents(
			getter: { segmentedControl in
				segmentedControl.selectedSegmentIndex
			}, setter: { segmentedControl, value in
				segmentedControl.selectedSegmentIndex = value
			}
		)
	}

	/// Binds to enabled state for specific segment.
	func enabledForSegment(at index: Int) -> Binder<Bool> {
		Binder(base) { segmentedControl, segmentEnabled in
			segmentedControl.setEnabled(segmentEnabled, forSegmentAt: index)
		}
	}

	/// Binds to title for specific segment.
	func titleForSegment(at index: Int) -> Binder<String?> {
		Binder(base) { segmentedControl, title in
			segmentedControl.setTitle(title, forSegmentAt: index)
		}
	}

	/// Binds to image for specific segment.
	func imageForSegment(at index: Int) -> Binder<UIImage?> {
		Binder(base) { segmentedControl, image in
			segmentedControl.setImage(image, forSegmentAt: index)
		}
	}
}

#endif
