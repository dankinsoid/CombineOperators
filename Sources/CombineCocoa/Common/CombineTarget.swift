//
//  CombineTarget.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 7/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

import Combine

class CombineTarget: NSObject, Cancellable {
    
    override init() {
        super.init()
#if TRACE_RESOURCES
        _ = Resources.incrementTotal()
#endif

#if DEBUG
        DispatchQueue.ensureRunningOnMainThread()
#endif
    }
    
    func cancel() {}

#if TRACE_RESOURCES
    deinit {
        _ = Resources.decrementTotal()
    }
#endif
}
