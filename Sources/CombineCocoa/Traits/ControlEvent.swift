import Foundation
import Combine

/// A protocol that extends `ControlEvent`.
@available(iOS 13.0, macOS 10.15, *)
public protocol ControlEventType: Publisher {

    /// - returns: `ControlEvent` interface
    func asControlEvent() -> ControlEvent<Output>
}

/**
    A trait for `Publisher`/`Publisher` that represents an event on a UI element.

    Properties:

    - it doesn’t send any initial value on subscription,
    - it `Complete`s the sequence when the control deallocates,
    - it never errors out
    - it delivers events on `MainScheduler.instance`.

    **The implementation of `ControlEvent` will ensure that sequence of events is being subscribed on main scheduler
     (`subscribe(on: ConcurrentMainScheduler.instance)` behavior).**

    **It is the implementor’s responsibility to make sure that all other properties enumerated above are satisfied.**

    **If they aren’t, using this trait will communicate wrong properties, and could potentially break someone’s code.**

    **If the `events` observable sequence passed into the initializer doesn’t satisfy all enumerated
     properties, don’t use this trait.**
*/
@available(iOS 13.0, macOS 10.15, *)
public struct ControlEvent<PropertyType>: ControlEventType {
	
	public typealias Failure = Never
    public typealias Output = PropertyType

    let events: AnyPublisher<PropertyType, Failure>

    /// Initializes control event with a observable sequence that represents events.
    ///
    /// - parameter events: Publisher sequence that represents events.
    /// - returns: Control event created with a observable sequence of events.
	public init<Ev: Publisher>(events: Ev) where Ev.Output == Output {
		self.events = events.catch({_ in Empty() }).eraseToAnyPublisher()
	}

	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, PropertyType == S.Input {
		events.receive(subscriber: subscriber)
	}
	
	public func asControlEvent() -> ControlEvent<PropertyType> {
		self
	}
}
