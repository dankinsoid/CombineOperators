import Combine
import Foundation

/// A protocol that extends `ControlEvent`.
public protocol ControlEventType: Publisher {

	/// - returns: `ControlEvent` interface
	func asControlEvent() -> ControlEvent<Output>
}

/// Publisher trait representing UI control events (button taps, value changes, etc.).
///
/// Guarantees:
/// - No initial value on subscription
/// - Completes when control deallocates
/// - Never errors (failures caught internally)
/// - Delivers on main thread
///
/// ```swift
/// button.cb.tap // ControlEvent<Void>
///     .sink { print("Button tapped") }
/// ```
///
/// **Warning:** Only use this trait if your publisher satisfies all properties above.
public struct ControlEvent<PropertyType>: ControlEventType {

	public typealias Failure = Never
	public typealias Output = PropertyType

	let events: AnyPublisher<PropertyType, Failure>

	/// Creates control event from publisher. Errors are caught and suppressed.
	public init<Ev: Publisher>(events: Ev) where Ev.Output == Output {
		self.events = events.catch { _ in Empty() }.eraseToAnyPublisher()
	}

	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, PropertyType == S.Input {
		events.receive(subscriber: subscriber)
	}

	public func asControlEvent() -> ControlEvent<PropertyType> {
		self
	}
}
