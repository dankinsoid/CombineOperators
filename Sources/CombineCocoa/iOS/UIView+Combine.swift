#if canImport(UIKit)
import Combine
import UIKit

public extension Reactive where Base: UIView {

	/// Binds to accessibility identifier.
	var accessibilityIdentifier: Binder<String?> {
		Binder(base, binding: { $0.accessibilityIdentifier = $1 })
	}

	/// Binds to view's transform.
	var transform: Binder<CGAffineTransform> {
		Binder(base, binding: { $0.transform = $1 })
	}

	/// Emits once when view moves to window (first occurrence only).
	var movedToWindow: AnyPublisher<Void, Never> {
		AnyPublisher<Void, Never>.create { [weak base] in
			let cancellable = base?.observeMoveToWindow(subscriber: $0)
			return AnyCancellable {
				cancellable?.cancel()
			}
		}
		.map { [weak base] _ in base?.window != nil }
		.prepend(base.window != nil)
		.filter { $0 == true }
		.map { _ in }
		.prefix(1)
		.eraseToAnyPublisher()
	}

	/// Emits whether view is visible on screen (within window bounds).
	///
	/// Tracks frame changes across view hierarchy. Useful for lazy loading.
	var isOnScreen: AnyPublisher<Bool, Never> {
		.create { [weak base] sbr in
			AnyCancellable(base?.observeIsOnScreen { _ = sbr.receive($0) } ?? {})
		}
		.silenсeFailure()
		.eraseToAnyPublisher()
	}

	/// Emits view's frame in its own coordinate space on changes.
	///
	/// Observes layer position, bounds, and transform. Skips duplicate frames.
	var frame: AnyPublisher<CGRect, Never> {
		.create { [weak base] observer in
			AnyCancellable(base?.observeFrame { _ = observer.receive($0.frame) } ?? {})
		}
		.silenсeFailure()
		.removeDuplicates()
		.eraseToAnyPublisher()
	}

	/// Emits view's frame in window coordinate space on changes.
	///
	/// Tracks entire view hierarchy for comprehensive frame monitoring.
	var frameOnWindow: AnyPublisher<CGRect, Never> {
		.create { [weak base] sbr in
			AnyCancellable(base?.observeFrameInWindow { _ = sbr.receive($0) } ?? {})
		}
		.silenсeFailure()
		.removeDuplicates()
		.eraseToAnyPublisher()
	}

	/// Emits layer's `isHidden` value on changes.
	var isHidden: AnyPublisher<Bool, Never> {
		value(at: \.isHidden)
	}

	/// Emits layer's opacity as `CGFloat` on changes.
	var alpha: AnyPublisher<CGFloat, Never> {
		value(at: \.opacity).map { CGFloat($0) }.eraseToAnyPublisher()
	}

	private func value<T: Equatable>(at keyPath: KeyPath<CALayer, T>) -> AnyPublisher<T, Never> {
		.create { [weak base] sbr in
			if let observer = base?.layer.observe(keyPath, { _ = sbr.receive($0) }) {
				base?.layerObservers.observers.append(observer)
				return AnyCancellable(observer.invalidate)
			} else {
				return AnyCancellable()
			}
		}
		.silenсeFailure()
		.eraseToAnyPublisher()
	}
}

private final class MovedToWindowObserver: UIView {

	var onMoveToWindow: [AnySubscriber<Void, Never>] = []

	init() {
		super.init(frame: .zero)
		isHidden = true
		isUserInteractionEnabled = false
	}

	deinit {
		for item in onMoveToWindow {
			item.receive(completion: .finished)
		}
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		for item in onMoveToWindow {
			_ = item.receive(())
		}
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

	private var movedToWindowObserver: MovedToWindowObserver? {
		subviews.compactMap { $0 as? MovedToWindowObserver }.first ??
			subviews.compactMap(\.movedToWindowObserver).first
	}

	func observeMoveToWindow(subscriber: AnySubscriber<Void, Never>) -> AnyCancellable {
		let view: MovedToWindowObserver
		if let added = movedToWindowObserver {
			view = added
		} else {
			view = MovedToWindowObserver()
			addSubview(view)
		}
		view.onMoveToWindow.append(subscriber)
		return AnyCancellable {
			view.onMoveToWindow = view.onMoveToWindow.filter {
				$0.combineIdentifier != subscriber.combineIdentifier
			}
		}
	}

	@discardableResult
	func observeIsOnScreen(_ action: @escaping (Bool) -> Void) -> () -> Void {
		var prev = isOnScreen
		action(prev)
		return observeFrameInWindow { [weak self] in
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
			$0.observeFrame { [weak self] in
				guard let self, let window = self.window else { return }
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
		let block = { [weak self] in
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

private var layerObservrersKey = 0

fileprivate extension CALayer {

	func observe<T: Equatable>(_ keyPath: KeyPath<CALayer, T>, _ action: @escaping (T) -> Void) -> NSKeyValueObservation {
		observe(keyPath, options: [.new, .old, .initial]) { layer, change in
			guard let value = change.newValue, change.newValue != change.oldValue else { return }
			action(value)
		}
	}

	func observeFrame<T: Equatable>(_ keyPath: KeyPath<CALayer, T>, _ action: @escaping () -> Void) -> NSKeyValueObservation {
		observe(keyPath, options: [.new, .old]) { layer, change in
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

extension CATransform3D: @retroactive Equatable {

	private var ms: [CGFloat] { [m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44] }

	public static func == (_ lhs: CATransform3D, _ rhs: CATransform3D) -> Bool {
		lhs.ms == rhs.ms
	}
}
#endif
