#if os(iOS) || os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UIActivityIndicatorView {
	/// Binds to animation state (calls `startAnimating()`/`stopAnimating()`).
	var isAnimating: Binder<Bool> {
		Binder(base) { activityIndicator, active in
			if active {
				activityIndicator.startAnimating()
			} else {
				activityIndicator.stopAnimating()
			}
		}
	}
}

#endif
