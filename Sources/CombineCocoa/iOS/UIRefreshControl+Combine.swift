#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UIRefreshControl {
	/// Binds to refresh control state (calls `beginRefreshing()`/`endRefreshing()`).
	var isRefreshing: Binder<Bool> {
		Binder(base) { refreshControl, refresh in
			if refresh {
				refreshControl.beginRefreshing()
			} else {
				refreshControl.endRefreshing()
			}
		}
	}
}

#endif
