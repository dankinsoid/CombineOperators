//
//  UIGestureRecognizer+Combine.swift
//  CombineCocoa
//
//  Created by Carlos García on 10/6/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

// This should be only used from `MainScheduler`
@available(iOS 13.0, macOS 10.15, *)
final class GestureTarget<Recognizer: UIGestureRecognizer>: CombineTarget {
    typealias Callback = (Recognizer) -> Void
    
    let selector = #selector(ControlTarget.eventHandler(_:))
    
    weak var gestureRecognizer: Recognizer?
    var callback: Callback?
    
    init(_ gestureRecognizer: Recognizer, callback: @escaping Callback) {
        self.gestureRecognizer = gestureRecognizer
        self.callback = callback
        
        super.init()
        
        gestureRecognizer.addTarget(self, action: selector)

        let method = self.method(for: selector)
        if method == nil {
            fatalError("Can't find method")
        }
    }
    
    @objc func eventHandler(_ sender: UIGestureRecognizer) {
        if let callback = self.callback, let gestureRecognizer = self.gestureRecognizer {
            callback(gestureRecognizer)
        }
    }
    
    override func cancel() {
        super.cancel()
        self.gestureRecognizer?.removeTarget(self, action: self.selector)
        self.callback = nil
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIGestureRecognizer {
    
    /// Reactive wrapper for gesture recognizer events.
    public var event: ControlEvent<Base> {
			ControlEvent(events: create { [weak control = self.base] observer in
            DispatchQueue.ensureRunningOnMainThread()

            guard let control = control else {
							observer.receive(completion: .finished)
							return AnyCancellable { }
            }
            
            let observer = GestureTarget(control) { control in
							_ = observer.receive(control)
            }
            
            return observer
        }.prefix(untilOutputFrom: deallocated)
			)
    }
    
}

#endif
