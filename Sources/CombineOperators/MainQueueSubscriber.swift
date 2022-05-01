//
//  File.swift
//  
//
//  Created by Данил Войдилов on 13.03.2021.
//

import Foundation
import Combine

public final class MainQueueSubscriber<S: Subscriber>: Subscriber {
	public typealias Input = S.Input
	public typealias Failure = S.Failure
	public let subscriber: S
	public var combineIdentifier: CombineIdentifier { subscriber.combineIdentifier }
	private var demand: Subscribers.Demand = .unlimited
	private let lock = NSRecursiveLock()
	
	public init(subscriber: S) {
		self.subscriber = subscriber
	}
	
	public func receive(subscription: Subscription) {
		onMain {
			self.subscriber.receive(subscription: subscription)
		}
	}
	
	public func receive(_ input: S.Input) -> Subscribers.Demand {
		if Thread.isMainThread {
			let _demand = subscriber.receive(input)
			lock.lock()
				demand = _demand
			lock.unlock()
			return _demand
		} else {
			DispatchQueue.main.async {
				self.lock.lock()
					self.demand = self.subscriber.receive(input)
				self.lock.unlock()
			}
			lock.lock()
			let _demand = demand
			lock.unlock()
			return _demand
		}
	}
	
	public func receive(completion: Subscribers.Completion<S.Failure>) {
		onMain {
			self.subscriber.receive(completion: completion)
		}
	}
	
	private func onMain(_ action: @escaping () -> Void) -> Void {
		if Thread.isMainThread {
			action()
		} else {
			DispatchQueue.main.async(execute: action)
		}
	}
}
