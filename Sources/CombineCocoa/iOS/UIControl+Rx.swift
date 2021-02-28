//
//  UIControl+Combine.swift
//  CombineCocoa
//
//  Created by Daniel Tartaglia on 5/23/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import CombineOperators
import UIKit

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UIControl {
    /// Reactive wrapper for target action pattern.
    ///
    /// - parameter controlEvents: Filter for observed event types.
    public func controlEvent(_ controlEvents: UIControl.Event) -> ControlEvent<()> {
			ControlEvent(events: create { [weak control = self.base] observer in
                DispatchQueue.ensureRunningOnMainThread()

                guard let control = control else {
									observer.receive(completion: .finished)
									return AnyCancellable { }
                }

                let controlTarget = ControlTarget(control: control, controlEvents: controlEvents) { _ in
                    _ = observer.receive()
                }

                return controlTarget
            }
            .prefix(untilOutputFrom: deallocated)
						.eraseToAnyPublisher()
				)
    }

    /// Creates a `ControlProperty` that is triggered by target/action pattern value updates.
    ///
    /// - parameter controlEvents: Events that trigger value update sequence elements.
    /// - parameter getter: Property value getter.
    /// - parameter setter: Property value setter.
    public func controlProperty<T>(
        editingEvents: UIControl.Event,
        getter: @escaping (Base) -> T,
				setter: @escaping (Base, T) -> Void
    ) -> ControlProperty<T> {
			let source: AnyPublisher<T, Error> = create { [weak weakControl = base] observer in
                guard let control = weakControl else {
                    observer.receive(completion: .finished)
									return AnyCancellable { }
                }

					_ = observer.receive(getter(control))

                let controlTarget = ControlTarget(control: control, controlEvents: editingEvents) { _ in
                    if let control = weakControl {
                        _ = observer.receive(getter(control))
                    }
                }
                
                return controlTarget
            }
            .prefix(untilOutputFrom: deallocated)
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
        return controlProperty(
            editingEvents: editingEvents,
            getter: getter,
            setter: setter
        )
    }
}

#endif
