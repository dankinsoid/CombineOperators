#if canImport(UIKit)

import UIKit
import Combine
import Foundation

@available(iOS 13.0, macOS 10.15, *)
public class TouchDownGestureRecognizer: UIGestureRecognizer {

    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        trigger
					.flatMap(maxPublishers: .max(1)) { [unowned self] _ -> AnyPublisher<Void, Never> in
                let trigger = Just(())
                guard self.state == .possible else {
									return trigger.eraseToAnyPublisher()
                }
							return trigger
								.delay(for: .microseconds(Int(minimumTouchDuration * 1_000_000)), scheduler: RunLoop.main)
								.eraseToAnyPublisher()
            }
            .sink(receiveValue: { [unowned self] _ in
                self.touches = self._touches
            })
					.store(in: &triggerDisposeBag)
    }

    public var minimumTouchDuration: TimeInterval = 0

    /**
     When set to `false`, it allows to bypass the touch ignoring mechanism in order to get absolutely all touch down events.
     Defaults to `true`.
     - note: See [ignore(_ touch: UITouch, for event: UIEvent)](https://developer.apple.com/documentation/uikit/uigesturerecognizer/1620010-ignore)
     */
    public var isTouchIgnoringEnabled: Bool = true

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

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        setTouches(from: event)
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        setTouches(from: event)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        setTouches(from: event)
    }

    public override  func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
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

    public override func reset() {
        super.reset()
        touches = []
    }

    public override func ignore(_ touch: UITouch, for event: UIEvent) {
        guard isTouchIgnoringEnabled else {
            return
        }
        super.ignore(touch, for: event)
    }

}

@available(iOS 13.0, macOS 10.15, *)
public typealias TouchDownConfiguration = Configuration<TouchDownGestureRecognizer>
@available(iOS 13.0, macOS 10.15, *)
public typealias TouchDownControlEvent = ControlEvent<TouchDownGestureRecognizer>
@available(iOS 13.0, macOS 10.15, *)
public typealias TouchDownPublisher = AnyPublisher<TouchDownGestureRecognizer, Never>

@available(iOS 13.0, macOS 10.15, *)
extension Factory where Gesture == CombineGestureRecognizer {

    /**
     Returns an `AnyFactory` for `TouchDownGestureRecognizer`
     - parameter configuration: A closure that allows to fully configure the gesture recognizer
     */
    public static func touchDown(configuration: TouchDownConfiguration? = nil) -> AnyFactory {
        make(configuration: configuration).abstracted()
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: CombineGestureView {

    /**
     Returns an observable `TouchDownGestureRecognizer` events sequence
     - parameter configuration: A closure that allows to fully configure the gesture recognizer
     */
    public func touchDownGesture(configuration: TouchDownConfiguration? = nil) -> TouchDownControlEvent {
			gesture(make(configuration: configuration))
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: TouchDownGestureRecognizer {

    /**
     Maps the observable `GestureRecognizer` events sequence to an observable sequence of force values.
     */
    public func asTouches() -> AnyPublisher<Set<UITouch>, Failure> {
			self.map { $0.touches }.eraseToAnyPublisher()
    }
}

#endif
