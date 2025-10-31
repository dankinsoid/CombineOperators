#if canImport(UIKit)

import Combine
import CombineOperators
import Foundation
import UIKit

public class TouchDownGestureRecognizer: UIGestureRecognizer {

	override public init(target: Any?, action: Selector?) {
		super.init(target: target, action: action)
		trigger
			.flatMap(maxPublishers: .max(1)) { [unowned self] _ -> AnyPublisher<Void, Never> in
				let trigger = Just(())
				guard state == .possible else {
					return trigger.eraseToAnyPublisher()
				}
				return trigger
					.delay(for: .microseconds(Int(minimumTouchDuration * 1_000_000)), scheduler: MainScheduler.instance)
					.eraseToAnyPublisher()
			}
			.sink(receiveValue: { [unowned self] _ in
				touches = _touches
			})
			.store(in: &triggerDisposeBag)
	}

	public var minimumTouchDuration: TimeInterval = 0

	/**
	 When set to `false`, it allows to bypass the touch ignoring mechanism in order to get absolutely all touch down events.
	 Defaults to `true`.
	 - note: See [ignore(_ touch: UITouch, for event: UIEvent)](https://developer.apple.com/documentation/uikit/uigesturerecognizer/1620010-ignore)
	 */
	public var isTouchIgnoringEnabled = true

	@nonobjc public var touches: Set<UITouch> = [] {
		didSet {
			if touches.isEmpty {
				if state == .possible {
					state = .cancelled
				} else {
					state = .ended
				}
			} else {
				if state == .possible {
					state = .began
				} else {
					state = .changed
				}
			}
		}
	}

	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesBegan(touches, with: event)
		setTouches(from: event)
	}

	override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesMoved(touches, with: event)
		setTouches(from: event)
	}

	override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesEnded(touches, with: event)
		setTouches(from: event)
	}

	override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesCancelled(touches, with: event)
		setTouches(from: event)
	}

	private var triggerDisposeBag = Set<AnyCancellable>()
	private let trigger = PassthroughSubject<Void, Never>()
	private var _touches: Set<UITouch> = []
	private func setTouches(from event: UIEvent) {
		_touches = (event.allTouches ?? []).filter { touch in
			[.began, .stationary, .moved].contains(touch.phase)
		}
		trigger.send()
	}

	override public func reset() {
		super.reset()
		touches = []
	}

	override public func ignore(_ touch: UITouch, for event: UIEvent) {
		guard isTouchIgnoringEnabled else {
			return
		}
		super.ignore(touch, for: event)
	}
}

public typealias TouchDownConfiguration = Configuration<TouchDownGestureRecognizer>
public typealias TouchDownControlEvent = ControlEvent<TouchDownGestureRecognizer>
public typealias TouchDownPublisher = AnyPublisher<TouchDownGestureRecognizer, Never>

public extension Factory where Gesture == CombineGestureRecognizer {

	/**
	 Returns an `AnyFactory` for `TouchDownGestureRecognizer`
	 - parameter configuration: A closure that allows to fully configure the gesture recognizer
	 */
	static func touchDown(configuration: TouchDownConfiguration? = nil) -> AnyFactory {
		make(configuration: configuration).abstracted()
	}
}

public extension Reactive where Base: CombineGestureView {

	/**
	 Returns an observable `TouchDownGestureRecognizer` events sequence
	 - parameter configuration: A closure that allows to fully configure the gesture recognizer
	 */
	func touchDownGesture(configuration: TouchDownConfiguration? = nil) -> TouchDownControlEvent {
		gesture(make(configuration: configuration))
	}
}

public extension Publisher where Output: TouchDownGestureRecognizer {

	/**
	 Maps the observable `GestureRecognizer` events sequence to an observable sequence of force values.
	 */
	func asTouches() -> AnyPublisher<Set<UITouch>, Failure> {
		map { $0.touches }.eraseToAnyPublisher()
	}
}

#endif
