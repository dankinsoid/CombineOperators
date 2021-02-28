//
//  File.swift
//  
//
//  Created by Данил Войдилов on 27.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
final class Observers<S: Subscriber>: Subscriber {
	typealias Input = S.Input
	typealias Failure = S.Failure
	let observers: [S]
	
	init(observers: [S]) {
		self.observers = observers
	}
	
	func receive(subscription: Subscription) {
		observers.forEach {
			$0.receive(subscription: subscription)
		}
	}
	
	func receive(completion: Subscribers.Completion<S.Failure>) {
		observers.forEach {
			$0.receive(completion: completion)
		}
	}
	
	func receive(_ input: S.Input) -> Subscribers.Demand {
		observers.map {
			$0.receive(input)
		}.min() ?? .unlimited
	}
	
}
