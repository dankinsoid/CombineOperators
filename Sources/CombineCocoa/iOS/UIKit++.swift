//
//  UIKit++.swift
//  TestProject
//
//  Created by Daniil on 21.10.2020.
//  Copyright © 2020 Daniil. All rights reserved.
//

import UIKit
import VDKit
import Combine
import CombineOperators

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIResponder {

	public var isFirstResponder: ControlProperty<Bool> {
		ControlProperty(
			values: methodInvoked(#selector(UIResponder.becomeFirstResponder))
				.merge(with: methodInvoked(#selector(UIResponder.resignFirstResponder)))
				.map { [weak view = self.base] _ in
					view?.isFirstResponder ?? false
				}
				.share()
				.prepend(base.isFirstResponder)
				.removeDuplicates(),
//				.multicast(subject: ReplaySubject(maxValues: 1))
//				.autoconnect(),
			valueSink: AnySubscriber<Bool, Never>(receiveValue: {[weak base] in
				if $0 {
					base?.becomeFirstResponder()
				} else {
					base?.resignFirstResponder()
				}
				return .unlimited
			})
		)
	}

}

private struct FullError: Error {}

@available(iOS 13.0, macOS 10.15, *)
extension Subscriber {

	public func animate(_ duration: TimeInterval, options: UIView.AnimationOptions = []) -> AnySubscriber<Input, Failure> {
		AnySubscriber(
			receiveSubscription: { subscription in
				self.receive(subscription: subscription)
			},
			receiveValue: { value in
				UIView.animate(duration, options: options, {
					_ = self.receive(value)
				})
				return .unlimited
			},
			receiveCompletion: { completion in
				UIView.animate(duration, options: options, {
					self.receive(completion: completion)
				})
			})
	}

}

@available(iOS 13.0, macOS 10.15, *)
extension Subscriber where Input == CGAffineTransform {

	public func scale() -> Subscribers.MapSubscriber<Self, CGFloat> {
		mapSubscriber { CGAffineTransform(scaleX: $0, y: $0) }
	}

	public func scale() -> Subscribers.MapSubscriber<Self, CGSize> {
		mapSubscriber { CGAffineTransform(scaleX: $0.width, y: $0.height) }
	}

	public func rotation() -> Subscribers.MapSubscriber<Self, CGFloat> {
		mapSubscriber { CGAffineTransform(rotationAngle: $0) }
	}

	public func translation() -> Subscribers.MapSubscriber<Self, CGPoint> {
		mapSubscriber { CGAffineTransform(translationX: $0.x, y: $0.y) }
	}

}
