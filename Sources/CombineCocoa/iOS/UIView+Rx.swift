//
//  File.swift
//  
//
//  Created by Данил Войдилов on 27.02.2021.
//

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIView {
	
	public var id: Binder<String?> {
		Binder(base, binding: { $0.accessibilityIdentifier = $1 })
	}
	
	public var transform: Binder<CGAffineTransform> {
		Binder(base, binding: { $0.transform = $1 })
	}
	
	public var movedToWindow: AnyPublisher<Void, Error> {
		methodInvoked(#selector(UIView.didMoveToWindow))
			.map {[weak base] _ in base?.window != nil }
			.prepend(base.window != nil)
			.filter { $0 }
			.map { _ in }
			.prefix(1)
			.eraseToAnyPublisher()
	}
	
	public var isOnScreen: AnyPublisher<Bool, Never> {
		create {[weak base] sbr in
			AnyCancellable(base?.observeIsOnScreen { _ = sbr.receive($0) } ?? {})
		}
		.skipFailure()
		.eraseToAnyPublisher()
	}
	
	public var frame: AnyPublisher<CGRect, Never> {
		create {[weak base] observer in
			AnyCancellable(base?.observeFrame { _ = observer.receive($0.frame) } ?? {})
		}
		.skipFailure()
		.removeDuplicates()
		.eraseToAnyPublisher()
	}
	
	public var frameOnWindow: AnyPublisher<CGRect, Never> {
		create {[weak base] sbr in
			AnyCancellable(base?.observeFrameInWindow { _ = sbr.receive($0) } ?? {})
		}
		.skipFailure()
		.removeDuplicates()
		.eraseToAnyPublisher()
	}
	
	public var willAppear: ControlEvent<Bool> {
		let source = movedToWindow.flatMap {[weak base] in
			base?.vc?.cb.methodInvoked(#selector(UIViewController.viewWillAppear)).map { $0.first as? Bool ?? false }
				.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
		}
		return ControlEvent(events: source)
	}
	
	public var didAppear: ControlEvent<Bool> {
		ControlEvent(events: movedToWindow.flatMap {[weak base] in
			base?.vc?.cb.methodInvoked(#selector(UIViewController.viewDidAppear)).map { $0.first as? Bool ?? false }
				.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
		})
	}
	
	public var willDisappear: ControlEvent<Bool> {
		ControlEvent(events: movedToWindow.flatMap {[weak base] in
			base?.vc?.cb.methodInvoked(#selector(UIViewController.viewWillDisappear)).map { $0.first as? Bool ?? false }
				.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
		})
	}
	
	public var didDisappear: ControlEvent<Bool> {
		ControlEvent(events: movedToWindow.flatMap {[weak base] in
			base?.vc?.cb.methodInvoked(#selector(UIViewController.viewDidDisappear)).map { $0.first as? Bool ?? false }
				.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
		})
	}
	
	public var layoutSubviews: ControlEvent<Void> {
		let source = self.methodInvoked(#selector(Base.layoutSubviews)).map { _ in }
		return ControlEvent(events: source)
	}
	
	public var isHidden: AnyPublisher<Bool, Never> {
		value(at: \.isHidden)
	}
	
	public var alpha: AnyPublisher<CGFloat, Never> {
		value(at: \.opacity).map { CGFloat($0) }.eraseToAnyPublisher()
	}
	
	public var isVisible: AnyPublisher<Bool, Never> {
		isHidden
			.combineLatest(alpha, isOnScreen, willAppear.map { _ in true }.merge(with: didDisappear.map { _ in false }).prepend(base.window != nil))
			.map { !$0.0 && $0.1 > 0 && $0.2 && $0.3 }
			.removeDuplicates()
			.eraseToAnyPublisher()
	}
	
	private func value<T: Equatable>(at keyPath: KeyPath<CALayer, T>) -> AnyPublisher<T, Never> {
		create {[weak base] sbr in
            if let observer = base?.layer.observe(keyPath, { _ = sbr.receive($0) }) {
                base?.layerObservers.observers.append(observer)
                return AnyCancellable(observer.invalidate)
            } else {
                return AnyCancellable()
            }
		}
		.skipFailure()
		.eraseToAnyPublisher()
	}

}

extension UIView {
	
	fileprivate var layerObservers: NSKeyValueObservations {
		let current = objc_getAssociatedObject(self, &layerObservrersKey) as? NSKeyValueObservations
		let bag = current ?? NSKeyValueObservations()
		if current == nil {
			objc_setAssociatedObject(self, &layerObservrersKey, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
		return bag
	}
	
	var superviews: [UIView] {
		superview.map { [$0] + $0.superviews } ?? []
	}
	
	var isOnScreen: Bool {
		window?.bounds.intersects(convert(bounds, to: window)) == true
	}
	
	@discardableResult
	func observeIsOnScreen(_ action: @escaping (Bool) -> Void) -> () -> Void {
		var prev = isOnScreen
		action(prev)
		return observeFrameInWindow {[weak self] in
			let new = self?.window?.bounds.intersects($0) == true
			if new != prev {
				action(new)
				prev = new
			}
		}
	}
	
	@discardableResult
	func observeFrameInWindow(_ action: @escaping (CGRect) -> Void) -> () -> Void {
		let list = ([self] + superviews).map {
			$0.observeFrame {[weak self] in
				guard let `self` = self, let window = self.window else { return }
				action($0.convert($0.bounds, to: window))
			}
		}
		return {
			list.forEach { $0() }
		}
	}
	
	@discardableResult
	func observeFrame(_ action: @escaping (UIView) -> Void) -> () -> Void {
		var observers: [NSKeyValueObservation] = []
		let block = {[weak self] in
			guard let it = self else { return }
			action(it)
		}
		observers.append(layer.observeFrame(\.position, block))
		observers.append(layer.observeFrame(\.bounds, block))
		observers.append(layer.observeFrame(\.transform, block))
		layerObservers.observers += observers
		action(self)
		return { observers.forEach { $0.invalidate() } }
	}
	
	fileprivate var vc: UIViewController? {
		(next as? UIViewController) ?? (next as? UIView)?.vc
	}
}

private var layerObservrersKey = "layerObservrersKey0000"

extension CALayer {
	
	fileprivate func observe<T: Equatable>(_ keyPath: KeyPath<CALayer, T>, _ action: @escaping (T) -> Void) -> NSKeyValueObservation {
		observe(keyPath, options: [.new, .old, .initial]) { (layer, change) in
			guard let value = change.newValue, change.newValue != change.oldValue else { return }
			action(value)
		}
	}

	fileprivate func observeFrame<T: Equatable>(_ keyPath: KeyPath<CALayer, T>, _ action: @escaping () -> Void) -> NSKeyValueObservation {
		observe(keyPath, options: [.new, .old]) { (layer, change) in
			guard change.newValue != change.oldValue else { return }
			action()
		}
	}
}

private final class NSKeyValueObservations {
	var observers: [NSKeyValueObservation] = []
	
	func invalidate() {
		observers.forEach { $0.invalidate() }
	}
}

extension CATransform3D: Equatable {
	
	private var ms: [CGFloat] { [m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44] }
	
	public static func ==(_ lhs: CATransform3D, _ rhs: CATransform3D) -> Bool {
		lhs.ms == rhs.ms
	}
}
