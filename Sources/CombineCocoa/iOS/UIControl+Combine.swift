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
			events: AnyPublisher<Void, Error>.create { [weak control = self.base] observer in
				DispatchQueue.ensureRunningOnMainThread()
				guard let control else {
					observer.receive(completion: .finished)
					return ManualAnyCancellable()
				}
				let controlTarget = ControlTarget(control: control, controlEvents: controlEvents) { _ in
					_ = observer.receive()
				}

				return controlTarget
			}
			.prefix(untilOutputFrom: onDeinit)
			.eraseToAnyPublisher()
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
			events: controlEvent(controlEvents).compactMap { [weak base] in
				base.map(getter)
			}
			.prepend(getter(base))
		)
	}

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
		editingEvents: UIControl.Event,
		getter: @escaping (Base) -> T,
		setter: @escaping (Base, T) -> Void
	) -> ControlProperty<T> {
		let source: AnyPublisher<T, Error> = .create { [weak weakControl = base] observer in
			guard let control = weakControl else {
				observer.receive(completion: .finished)
				return ManualAnyCancellable()
			}

			_ = observer.receive(getter(control))

			let controlTarget = ControlTarget(control: control, controlEvents: editingEvents) { _ in
				if let control = weakControl {
					_ = observer.receive(getter(control))
				}
			}

			return controlTarget
		}
		.prefix(untilOutputFrom: onDeinit)
		.eraseToAnyPublisher()

		let bindingObserver = Binder(base, binding: setter)

		return ControlProperty<T>(values: source, valueSink: bindingObserver)
	}

	/// This is a separate method to better communicate to public consumers that
	/// an `editingEvent` needs to fire for control property to be updated.
	internal func controlPropertyWithDefaultEvents<T>(
		editingEvents: UIControl.Event = [.allEditingEvents, .valueChanged],
		getter: @escaping (Base) -> T,
		setter: @escaping (Base, T) -> Void
	) -> ControlProperty<T> {
		controlProperty(
			editingEvents: editingEvents,
			getter: getter,
			setter: setter
		)
	}
}

#endif
