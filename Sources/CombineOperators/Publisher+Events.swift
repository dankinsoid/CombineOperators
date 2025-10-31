import Foundation
import Combine

extension Publisher {

	/// Performs side-effect for each emitted value.
	///
	/// ```swift
	/// publisher.onValue { print("Received: \($0)") }
	/// ```
	public func onValue(_ action: @escaping (Output) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveOutput: action)
	}

	/// Performs side-effect on failure.
	///
	/// ```swift
	/// publisher.onFailure { error in log(error) }
	/// ```
	public func onFailure(_ action: @escaping (Failure) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .failure(let error) = $0 {
				action(error)
			}
		})
	}

	/// Performs side-effect on successful completion.
	public func onFinished(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .finished = $0 {
				action()
			}
		})
	}

	/// Performs side-effect when subscription is received.
	public func onSubscribe(_ action: @escaping (Subscription) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveSubscription: action)
	}

	/// Performs side-effect when cancelled.
	public func onCancel(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCancel: action)
	}

	/// Performs side-effect when demand is requested.
	public func onRequest(_ action: @escaping (Subscribers.Demand) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveRequest: action)
	}
}
