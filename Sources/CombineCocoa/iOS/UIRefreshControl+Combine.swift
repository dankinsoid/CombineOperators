//
//  UIRefreshControl+Combine.swift
//  CombineCocoa
//
//  Created by Yosuke Ishikawa on 1/31/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import UIKit
import Combine

extension Reactive where Base: UIRefreshControl {
	/// Binds to refresh control state (calls `beginRefreshing()`/`endRefreshing()`).
	public var isRefreshing: Binder<Bool> {
        return Binder(self.base) { refreshControl, refresh in
            if refresh {
                refreshControl.beginRefreshing()
            } else {
                refreshControl.endRefreshing()
            }
        }
    }

}

#endif
