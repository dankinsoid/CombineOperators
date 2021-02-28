//
//  File.swift
//  
//
//  Created by Данил Войдилов on 28.02.2021.
//

import Foundation
import Combine
import CombineOperators

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: AnyObject {
	
	public func create<Output>(_ closure: @escaping (AnySubscriber<Output, Error>) -> Cancellable) -> Publishers.Create<Output, Error> {
		let id = UUID()
		let publisher = Publishers.Create<Output, Error> {[weak base] subscriber in
			let cancellable = closure(subscriber)
			return AnyCancellable {
				cancellable.cancel()
				if let base = base {
					Reactive(base).publishers.publishers[id] = nil
				}
			}
		}
		//publishers.publishers[id] = publisher
		return publisher
	}
	
	private var publishers: ReactivePublishers {
		if let result = objc_getAssociatedObject(base, &publishersKey) as? ReactivePublishers {
			return result
		}
		let result = ReactivePublishers()
		objc_setAssociatedObject(base, &publishersKey, result, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return result
	}
	
}

private var publishersKey = "ReactivePublishersKey"

private final class ReactivePublishers {
	var publishers: [UUID: Any] = [:]
}
