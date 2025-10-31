#if canImport(UIKit)

import Combine
import UIKit.UIGestureRecognizerSubclass

public class ForceTouchGestureRecognizer: CombineGestureRecognizer {

	private var touch: UITouch?
	public var force: CGFloat {
		touch?.force ?? 0
	}

	public var maximumPossibleForce: CGFloat {
		touch?.maximumPossibleForce ?? 0
	}

	public var absoluteFractionCompleted: CGFloat {
		guard maximumPossibleForce > 0 else {
			return 0
		}
		return force / maximumPossibleForce
	}

	public var minimumFractionCompletedRequired: CGFloat = 0
	public var maximumFractionCompletedRequired: CGFloat = 1

	public var fractionCompleted: CGFloat {
		lerp(
			mapMin: minimumFractionCompletedRequired, to: 0,
			mapMax: maximumFractionCompletedRequired, to: 1,
			value: absoluteFractionCompleted
		)
	}

	override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesBegan(touches, with: event)

		guard state == .possible else { return }
		guard touch == nil else { return }
		guard let first = touches.first(where: { $0.phase == .began }) else { return }
		touch = first
		state = .began
	}

	override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesMoved(touches, with: event)
		guard let touch, touches.contains(touch), touch.phase == .moved else { return }
		state = .changed
	}

	override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesEnded(touches, with: event)
		guard let touch, touches.contains(touch), touch.phase == .ended else { return }
		self.touch = nil
		state = .ended
	}

	override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesCancelled(touches, with: event)
		guard let touch, touches.contains(touch), touch.phase == .cancelled else { return }
		self.touch = nil
		state = .cancelled
	}
}

public typealias ForceTouchConfiguration = Configuration<ForceTouchGestureRecognizer>
public typealias ForceTouchControlEvent = ControlEvent<ForceTouchGestureRecognizer>
public typealias ForceTouchPublisher = AnyPublisher<ForceTouchGestureRecognizer, Never>

public extension Factory where Gesture == CombineGestureRecognizer {

	/**
	 Returns an `AnyFactory` for `ForceTouchGestureRecognizer`
	 - parameter configuration: A closure that allows to fully configure the gesture recognizer
	 */
	static func forceTouch(configuration: ForceTouchConfiguration? = nil) -> AnyFactory {
		make(configuration: configuration).abstracted()
	}
}

public extension Reactive where Base: CombineGestureView {

	/**
	 Returns an observable `ForceTouchGestureRecognizer` events sequence
	 - parameter configuration: A closure that allows to fully configure the gesture recognizer
	 */
	func forceTouchGesture(configuration: ForceTouchConfiguration? = nil) -> ForceTouchControlEvent {
		gesture(make(configuration: configuration))
	}
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public extension Publisher where Output: ForceTouchGestureRecognizer {

	/**
	 Maps the observable `GestureRecognizer` events sequence to an observable sequence of force values.
	 */
	func asForce() -> AnyPublisher<CGFloat, Failure> {
		map { $0.force }.eraseToAnyPublisher()
	}

	func when(fractionCompletedExceeds threshold: CGFloat) -> AnyPublisher<Output, Failure> {
		let source = when(.changed)
		return when(.began)
			.map { _ -> AnyPublisher<Output, Never> in
				source
					.filter {
						if threshold == 0 {
							return $0.fractionCompleted > threshold
						} else {
							return $0.fractionCompleted >= threshold
						}
					}
					.prefix(1)
					.skipFailure()
					.eraseToAnyPublisher()
			}
			.switchToLatest()
			.eraseToAnyPublisher()
	}
}

private func lerp<T: FloatingPoint>(_ v0: T, _ v1: T, _ t: T) -> T {
	v0 + (v1 - v0) * t
}

private func lerp<T: FloatingPoint>(mapMin: T, to min: T, mapMax: T, to max: T, value: T) -> T {
	lerp(min, max, (value - mapMin) / (mapMax - mapMin))
}

#endif
