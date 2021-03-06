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

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIRefreshControl {
    /// Bindable sink for `beginRefreshing()`, `endRefreshing()` methods.
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
