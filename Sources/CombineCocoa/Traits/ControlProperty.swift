import Foundation
import Combine
import CombineOperators

/// Protocol that enables extension of `ControlProperty`.
public protocol ControlPropertyType: Publisher, Subscriber where Output == Input {

    /// - returns: `ControlProperty` interface
    func asControlProperty() -> ControlProperty<Output>
}

/// Publisher/Subscriber trait representing UI control properties (text, isEnabled, etc.).
///
/// Represents initial value + user-initiated changes only (programmatic changes excluded).
///
/// Guarantees:
/// - Replays last value on subscription (stateful)
/// - Completes when control deallocates
/// - Never errors (failures caught internally)
/// - Delivers on main thread
/// - Bidirectional binding support via `Subscriber` conformance
///
/// ```swift
/// textField.cb.text // ControlProperty<String?>
///     .sink { print("Text: \($0 ?? "")") }
///
/// publisher.subscribe(textField.cb.text) // Bind to property
/// ```
///
/// **Warning:** Only use this trait if your publisher satisfies all properties above.
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

	/// User-initiated value changes only (skips initial value).
	///
	/// Excludes programmatic changes. Emits on every user interaction, even if value
	/// doesn't change.
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
	/// Transforms optional string property to non-optional (nil → "").
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
