import Foundation
import Combine
import CombineOperators

/// Protocol that enables extension of `ControlProperty`.
public protocol ControlPropertyType: Publisher, Subscriber where Output == Input {

    /// - returns: `ControlProperty` interface
    func asControlProperty() -> ControlProperty<Output>
}

/**
    Trait for `Publisher`/`Publisher` that represents property of UI element.
 
    Sequence of values only represents initial control value and user initiated value changes.
    Programmatic value changes won't be reported.

    It's properties are:

    - `shareReplay(1)` behavior
        - it's stateful, upon subscription (calling subscribe) last element is immediately replayed if it was produced
    - it will `Complete` sequence on control being deallocated
    - it never errors out
    - it delivers events on `MainScheduler.instance`

    **The implementation of `ControlProperty` will ensure that sequence of values is being subscribed on main scheduler
    (`subscribe(on: ConcurrentMainScheduler.instance)` behavior).**

    **It is implementor's responsibility to make sure that that all other properties enumerated above are satisfied.**

    **If they aren't, then using this trait communicates wrong properties and could potentially break someone's code.**

    **In case `values` observable sequence that is being passed into initializer doesn't satisfy all enumerated
    properties, please don't use this trait.**
*/
public struct ControlProperty<PropertyType>: ControlPropertyType {
	public typealias Output = PropertyType
	public typealias Failure = Never
	public var combineIdentifier: CombineIdentifier { valueSink.combineIdentifier }

    let values: AnyPublisher<PropertyType, Failure>
    let valueSink: AnySubscriber<PropertyType, Failure>

    /// Initializes control property with a observable sequence that represents property values and observer that enables
    /// binding values to property.
    ///
    /// - parameter values: Publisher sequence that represents property values.
    /// - parameter valueSink: Observer that enables binding values to control property.
    /// - returns: Control property created with a observable sequence of values and an observer that enables binding values
    /// to property.
    public init<Values: Publisher, Sink: Subscriber>(values: Values, valueSink: Sink) where PropertyType == Values.Output, PropertyType == Sink.Input, Sink.Failure == Never {
        self.values = values.receive(on: MainScheduler.instance).catch({ _ in Empty() }).eraseToAnyPublisher()
		self.valueSink = AnySubscriber(valueSink)
	}

    /// `ControlEvent` of user initiated value changes. Every time user updates control value change event
    /// will be emitted from `changed` event.
    ///
    /// Programmatic changes to control value won't be reported.
    ///
    /// It contains all control property values except for first one.
    ///
    /// The name only implies that sequence element will be generated once user changes a value and not that
    /// adjacent sequence values need to be different (e.g. because of interaction between programmatic and user updates,
    /// or for any other reason).
    public var changed: ControlEvent<PropertyType> {
        ControlEvent(events: self.values.dropFirst(1))
    }

    /// - returns: `ControlProperty` interface.
    public func asControlProperty() -> ControlProperty<PropertyType> {
        self
    }
	
	public func receive(subscription: Subscription) {
		valueSink.receive(subscription: subscription)
	}
	
	public func receive(completion: Subscribers.Completion<Never>) {
		valueSink.receive(completion: completion)
	}
	
	public func receive(_ input: PropertyType) -> Subscribers.Demand {
		valueSink.receive(input)
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, PropertyType == S.Input {
		values.receive(subscriber: subscriber)
	}
	
}

extension ControlPropertyType where Output == String? {
    /// Transforms control property of type `String?` into control property of type `String`.
    public var orEmpty: ControlProperty<String> {
        let original: ControlProperty<String?> = self.asControlProperty()
        let values = original.values.map { $0 ?? "" }
        let valueSink = Subscribers.Sink<String, Never> { _ in
            original.valueSink.receive(completion: .finished)
        } receiveValue: {
            _ = original.valueSink.receive($0)
        }
        return ControlProperty<String>(values: values, valueSink: valueSink)
    }
	
}
