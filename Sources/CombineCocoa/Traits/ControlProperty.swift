import Combine
import CombineOperators
import Foundation

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

	let values: AnyPublisher<PropertyType, Never>
	let valueSink: AnySubscriber<PropertyType, Never>

	/// Creates control property from publisher and subscriber for bidirectional binding.
	///
	/// Values are delivered on main thread. Errors are caught and suppressed.
	public init<Values: Publisher, Sink: Subscriber>(values: Values, valueSink: Sink) where PropertyType == Values.Output, PropertyType == Sink.Input {
		self.values = values
            .receive(on: MainScheduler.instance)
            .silenсeFailure(complete: false)
            .endless()
            .eraseToAnyPublisher()
        self.valueSink = AnySubscriber(valueSink.nonFailing())
	}

	/// User-initiated value changes only (skips initial value).
	///
	/// Excludes programmatic changes. Emits on every user interaction, even if value
	/// doesn't change.
	public var changed: ControlEvent<PropertyType> {
		ControlEvent(events: values.dropFirst(1))
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

public extension ControlPropertyType {
    
    /// Transforms property values using provided mapping functions.
    func map<T>(
        get transform: @escaping (Output) -> T,
        set reverseTransform: @escaping (T) -> Output
    ) -> ControlProperty<T> {
        let original = asControlProperty()
        let values = original.values.map(transform)
        let valueSink = AnySubscriber<T, Never> { subscription in
            original.valueSink.receive(subscription: subscription)
        } receiveValue: { value in
            let transformed = reverseTransform(value)
            return original.valueSink.receive(transformed)
        } receiveCompletion: { completion in
            original.valueSink.receive(completion: .finished)
        }
        return ControlProperty<T>(values: values, valueSink: valueSink)
    }
}

public extension ControlPropertyType where Output == String? {

	/// Transforms optional string property to non-optional (nil → "").
	var orEmpty: ControlProperty<String> {
        map(
            get: { $0 ?? "" },
            set: { $0 }
        )
	}
}
