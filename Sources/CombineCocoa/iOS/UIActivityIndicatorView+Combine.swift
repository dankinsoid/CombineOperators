//
//  UIActivityIndicatorView+Combine.swift
//  CombineCocoa
//
//  Created by Ivan Persidskiy on 02/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

extension Reactive where Base: UIActivityIndicatorView {
	/// Binds to animation state (calls `startAnimating()`/`stopAnimating()`).
	public var isAnimating: Binder<Bool> {
        Binder(self.base) { activityIndicator, active in
            if active {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
            }
        }
    }
}

#endif
