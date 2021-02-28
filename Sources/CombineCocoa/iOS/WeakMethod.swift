//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
public struct WeakMethod<T: AnyObject, Input>: Subscriber {
	public typealias Failure = Never
	public let combineIdentifier: CombineIdentifier
	private(set) public weak var object: T?
	public let method: (T) -> (Input) -> Void
	
	init(object: T, method: @escaping (T) -> (Input) -> ()) {
		self.object = object
		self.combineIdentifier = CombineIdentifier(object)
		self.method = method
	}
	
	public func receive(subscription: Subscription) {}
	
	public func receive(_ input: Input) -> Subscribers.Demand {
		guard let obj = object else {
			return .none
		}
		method(obj)(input)
		return .unlimited
	}
	
	public func receive(completion: Subscribers.Completion<Never>) {}
	
}
