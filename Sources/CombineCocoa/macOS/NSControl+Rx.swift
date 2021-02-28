//
//  NSControl+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 5/31/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(macOS)

import Cocoa
import Combine

private var rx_value_key: UInt8 = 0
private var rx_control_events_key: UInt8 = 0
@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: NSControl {

    /// Reactive wrapper for control event.
    public var controlEvent: ControlEvent<()> {
        DispatchQueue.ensureRunningOnMainThread()

        let source = self.lazyInstanceAnyPublisher(&rx_control_events_key) { () -> AnyPublisher<Void, Error> in
						create { [weak control = self.base] observer in
                DispatchQueue.ensureRunningOnMainThread()

                guard let control = control else {
									observer.receive(completion: .finished)
									return AnyCancellable { }
                }

                let observer = ControlTarget(control: control) { _ in
                    _ = observer.receive()
                }
                
                return observer
            }
            .prefix(untilOutputFrom: self.deallocated)
						.share()
						.eraseToAnyPublisher()
        }

        return ControlEvent(events: source)
    }

    /// Creates a `ControlProperty` that is triggered by target/action pattern value updates.
    ///
    /// - parameter getter: Property value getter.
    /// - parameter setter: Property value setter.
    public func controlProperty<T>(
        getter: @escaping (Base) -> T,
        setter: @escaping (Base, T) -> Void
    ) -> ControlProperty<T> {
        DispatchQueue.ensureRunningOnMainThread()

        let source = self.lazyInstanceAnyPublisher(&rx_value_key) { () -> AnyPublisher<(), Error> in
                create { [weak weakControl = self.base] (observer: AnySubscriber<(), Error>) in
                    guard let control = weakControl else {
											observer.receive(completion: .finished)
											return AnyCancellable { }
                    }

									_ = observer.receive()

                    let observer = ControlTarget(control: control) { _ in
                        if weakControl != nil {
													_ = observer.receive()
                        }
                    }

                    return observer
                }
                .prefix(untilOutputFrom: self.deallocated)
                .share()
								.eraseToAnyPublisher()
            }
            .compactMap { [weak base] _ in
								base.map(getter)
            }

        let bindingObserver = Binder(self.base, binding: setter)

        return ControlProperty(values: source, valueSink: bindingObserver)
    }
}


#endif
