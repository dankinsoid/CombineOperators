import Combine
import Foundation

public extension Publishers {

	/// Bridges Swift Concurrency (async/await) with Combine.
	///
	/// Creates a publisher that executes an async operation and delivers results
	/// on the main thread. Useful for integrating modern async APIs with Combine-based code.
	struct Async<Output, Failure: Error>: Publisher {
		
		private let operation: ((Output) -> Void) async -> Result<Void, Failure>
		
		public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
			let subscription = AsyncSubscription(subscriber: subscriber, operation: operation)
			subscriber.receive(subscription: subscription)
		}
		
		private final class AsyncSubscription<S: Subscriber>: Subscription where Failure == S.Failure, Output == S.Input {
			
			private var subscriber: S?
			private var operation: ((Output) -> Void) async -> Result<Void, Failure>
			private let lock = NSLock()
			
			init(
				subscriber: S,
				operation: @escaping ((Output) -> Void) async -> Result<Void, Failure>
			) {
				self.subscriber = subscriber
				self.operation = operation
			}
			
			func request(_ demand: Subscribers.Demand) {
				Task {
					let result = await operation { [weak self] output in
						guard let self = self else { return }
						
						let localSubscriber = self.lock.withLock { self.subscriber }
						
						if let subscriber = localSubscriber {
							onMainIfNeeded {
								_ = subscriber.receive(output)
							}
						}
					}
					
					self.cancel()
					
					switch result {
					case .success:
						let finalSubscriber = lock.withLock { self.subscriber }
						onMainIfNeeded {
							finalSubscriber?.receive(completion: .finished)
						}
					case let .failure(error):
						let finalSubscriber = lock.withLock { self.subscriber }
						onMainIfNeeded {
							finalSubscriber?.receive(completion: .failure(error))
						}
					}
				}
			}
			
			func cancel() {
				lock.lock()
				subscriber = nil
				operation = { _ in .success(()) }
				lock.unlock()
			}
		}
	}
}

private func onMainIfNeeded(_ operation: @escaping () -> Void) {
	if Thread.isMainThread {
		operation()
	} else {
		DispatchQueue.main.async {
			operation()
		}
	}
}

public extension Publishers.Async where Failure == Error {

	/// Creates a publisher from a throwing async operation with multiple emissions.
	///
	/// The `send` closure can be called multiple times during execution.
	/// All values are delivered on the main thread.
	///
	/// ```swift
	/// Publishers.Async<String, Error> { send in
	///     for i in 1...5 {
	///         send("Update \(i)")
	///         try await Task.sleep(nanoseconds: 100_000_000)
	///     }
	/// }
	/// ```
	init(operation: @escaping ((Output) -> Void) async throws -> Void) {
		self.init { send in
			do {
				try await operation(send)
				return .success(())
			} catch {
				return .failure(error)
			}
		}
	}

	/// Creates a publisher from a throwing async operation with a single emission.
	///
	/// Simpler variant for operations that produce one value.
	///
	/// ```swift
	/// Publishers.Async {
	///     try await fetchUserData()
	/// }
	/// ```
	init(operation: @escaping () async throws -> Output) {
		self.init { send in
			do {
				let output = try await operation()
				send(output)
				return .success(())
			} catch {
				return .failure(error)
			}
		}
	}
}

public extension Publishers.Async where Failure == Never {

	/// Creates a publisher from a non-throwing async operation with multiple emissions.
	///
	/// For async operations that cannot fail.
	init(operation: @escaping ((Output) -> Void) async -> Void) {
		self.init { send in
			await operation(send)
			return .success(())
		}
	}

	/// Creates a publisher from a non-throwing async operation with a single emission.
	init(operation: @escaping () async -> Output) {
		self.init { send in
			let output = await operation()
			send(output)
			return .success(())
		}
	}
}

public extension Publisher {

	/// Discards all output values, emitting only Void.
	///
	/// Useful when you only care about completion, not the values.
	///
	/// ```swift
	/// dataPublisher
	///     .void  // Ignores data, tracks completion only
	/// ```
	var void: Publishers.Map<Self, Void> {
		map { _ in () }
	}
}
