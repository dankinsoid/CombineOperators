import Combine
import Foundation

public extension Publisher {

	/// Performs side-effect for each emitted value.
	///
	/// ```swift
	/// publisher.onValue { print("Received: \($0)") }
	/// ```
	func onValue(_ action: @escaping (Output) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveOutput: action)
	}

	/// Performs side-effect on failure.
	///
	/// ```swift
	/// publisher.onFailure { error in log(error) }
	/// ```
	func onFailure(_ action: @escaping (Failure) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case let .failure(error) = $0 {
				action(error)
			}
		})
	}

	/// Performs side-effect on successful completion.
	func onFinished(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .finished = $0 {
				action()
			}
		})
	}

	/// Performs side-effect when subscription is received.
	func onSubscribe(_ action: @escaping (Subscription) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveSubscription: action)
	}

	/// Performs side-effect when cancelled.
	func onCancel(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCancel: action)
	}

	/// Performs side-effect when demand is requested.
	func onRequest(_ action: @escaping (Subscribers.Demand) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveRequest: action)
	}
}
