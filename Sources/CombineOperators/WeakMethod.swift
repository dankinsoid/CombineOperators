//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
public final class WeakMethod<T: AnyObject, Input>: Subscriber {
	public typealias Failure = Never
	private(set) public weak var object: T?
	public let method: (T) -> (Input) -> Void
	
	public init(_ method: @escaping (T) -> (Input) -> (), on object: T) {
		self.object = object
		self.method = method
	}
	
	public func receive(subscription: Subscription) {
		subscription.request(.unlimited)
	}
	
	public func receive(_ input: Input) -> Subscribers.Demand {
		guard let obj = object else {
			return .none
		}
		method(obj)(input)
		return .unlimited
	}
	
	public func receive(completion: Subscribers.Completion<Never>) {}
	
}
