//
//  UIBarButtonItem+Combine.swift
//  CombineCocoa
//
//  Created by Daniel Tartaglia on 5/31/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

private var rx_tap_key: UInt8 = 0
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIBarButtonItem {
    /// Reactive wrapper for target action pattern on `self`.
    public var tap: ControlEvent<()> {
        let source = lazyInstanceAnyPublisher(&rx_tap_key) { () -> AnyPublisher<(), Error> in
            .create { [weak control = self.base] observer in
                guard let control = control else {
                    observer.receive(completion: .finished)
                    return AnyCancellable {}
                }
                let target = BarButtonItemTarget(barButtonItem: control) {
                    _ = observer.receive()
                }
                return target
            }
            .prefix(untilOutputFrom: self.deallocated)
            .share()
            .eraseToAnyPublisher()
        }
        return ControlEvent(events: source)
    }
}


@objc
@available(iOS 13.0, macOS 10.15, *)
final class BarButtonItemTarget: CombineTarget {
    typealias Callback = () -> Void
    
    weak var barButtonItem: UIBarButtonItem?
    var callback: Callback!
    
    init(barButtonItem: UIBarButtonItem, callback: @escaping () -> Void) {
        self.barButtonItem = barButtonItem
        self.callback = callback
        super.init()
        barButtonItem.target = self
        barButtonItem.action = #selector(BarButtonItemTarget.action(_:))
    }
    
    override func cancel() {
        super.cancel()
#if DEBUG
        DispatchQueue.ensureRunningOnMainThread()
#endif
        
        barButtonItem?.target = nil
        barButtonItem?.action = nil
        
        callback = nil
    }
    
    @objc func action(_ sender: AnyObject) {
        callback()
    }
    
}

#endif
