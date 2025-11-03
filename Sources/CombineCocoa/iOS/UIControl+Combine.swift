#if os(iOS) || os(tvOS)

import Combine
import CombineOperators
import UIKit

public extension Reactive where Base: UIControl {

    /// Reactive wrapper for target-action pattern events.
    ///
    /// ```swift
    /// button.cb.controlEvent(.touchUpInside)
    ///     .sink { print("Tapped") }
    /// ```
    func controlEvent(_ controlEvents: UIControl.Event) -> ControlEvent<Void> {
        ControlEvent(
            events: ControlPublisher(control: base, events: controlEvents)
                .prefix(untilOutputFrom: onDeinit)
                .map { _ in () }
                .share()
        )
    }

    /// Creates read-only control event that emits property values on control events.
    ///
    /// Emits initial value immediately, then on each control event.
    func controlProperty<T>(
        _ getter: @escaping (Base) -> T,
        on controlEvents: UIControl.Event = .valueChanged
    ) -> ControlEvent<T> {
        ControlEvent(
            events: Deferred { [weak base] () -> AnyPublisher<T, Never> in
                guard let base else {
                    return Empty<T, Never>(completeImmediately: true).eraseToAnyPublisher()
                }
                return ControlPublisher(control: base, events: controlEvents)
                    .prefix(untilOutputFrom: onDeinit)
                    .map(getter)
                    .share()
                    .prepend(getter(base))
                    .eraseToAnyPublisher()
            }
        )
    }
}

public extension Reactive where Base: UIControl {

	/// Creates bidirectional control property with getter/setter.
	///
	/// Enables both observing and binding control values.
	///
	/// ```swift
	/// let property = slider.cb.controlProperty(
	///     editingEvents: .valueChanged,
	///     getter: { $0.value },
	///     setter: { $0.value = $1 }
	/// )
	/// ```
	func controlProperty<T>(
		editingEvents: UIControl.Event = [.allEditingEvents, .valueChanged],
		getter: @escaping (Base) -> T,
		setter: @escaping (Base, T) -> Void
	) -> ControlProperty<T> {
        let source = Deferred { [weak base] () -> AnyPublisher<T, Never> in
            guard let base else {
                return Empty<T, Never>(completeImmediately: true).eraseToAnyPublisher()
            }
            return ControlPublisher(control: base, events: editingEvents)
                .prefix(untilOutputFrom: onDeinit)
                .map(getter)
                .share()
                .prepend(getter(base))
                .eraseToAnyPublisher()
        }

		let bindingObserver = Binder(base, binding: setter)

		return ControlProperty<T>(values: source, valueSink: bindingObserver)
	}
}

#endif
