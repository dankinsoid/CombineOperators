//
//  File.swift
//  
//
//  Created by Данил Войдилов on 27.02.2021.
//

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIStackView {
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (T, V, Int) -> Void) -> Binder<[T]> {
		Binder(base) {
			$0.update(items: $1, create: create, update: update)
		}
	}
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (V) -> AnySubscriber<T, Error>) -> Binder<[T]> {
		self.update(create: create) { value, view, _ in
			_ = update(view).receive(value)
		}
	}
	
}
