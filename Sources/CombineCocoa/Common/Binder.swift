//
//  Binder.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 9/17/17.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

import Foundation
import Combine

/**
 Observer that enforces interface binding rules:
 * can't bind errors (in debug builds binding of errors causes `fatalError` in release builds errors are being logged)
 * ensures binding is performed on a specific scheduler

 `Binder` doesn't retain target and in case target is released, element isn't bound.
 
 By default it binds elements on main scheduler.
 */
@available(iOS 13.0, macOS 10.15, *)
public final class Binder<Input>: Subscriber {
    public typealias Failure = Never
    
    private let binding: (Input) -> Void

    /// Initializes `Binder`
    ///
    /// - parameter target: Target object.
    /// - parameter scheduler: Scheduler used to bind the events.
    /// - parameter binding: Binding logic.
	public init<Target: AnyObject, S: Scheduler>(_ target: Target, scheduler: S, binding: @escaping (Target, Input) -> Void) {
			weak var weakTarget = target
			self.binding = { element in
				scheduler.schedule {
					if let target = weakTarget {
						binding(target, element)
					}
				}
		}
	}
	
	public convenience init<Target: AnyObject>(_ target: Target, binding: @escaping (Target, Input) -> Void) {
		self.init(target, scheduler: DispatchQueue.main, binding: binding)
	}
	
	public func receive(subscription: Subscription) {}
	
	public func receive(_ input: Input) -> Subscribers.Demand {
		binding(input)
		return .unlimited
	}
	
	public func receive(completion: Subscribers.Completion<Never>) {}

}
