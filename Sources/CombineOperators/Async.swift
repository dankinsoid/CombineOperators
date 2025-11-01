import Combine
import Foundation

public extension Publishers {

	/// Bridges Swift Concurrency (async/await) with Combine.
	///
	/// Creates a publisher that executes an async operation and delivers results
	/// on the main thread. Useful for integrating modern async APIs with Combine-based code.
	struct Async<Output, Failure: Error>: Publisher {

        let priority: TaskPriority?
		private let operation: ((Output) -> Void) async -> Result<Void, Failure>

		public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
			let subscription = AsyncSubscription(subscriber: subscriber, priority: priority, operation: operation)
			subscriber.receive(subscription: subscription)
		}

		private final class AsyncSubscription<S: Subscriber>: Subscription where Failure == S.Failure, Output == S.Input {

            private let priority: TaskPriority?
			private var subscriber: S?
			private var operation: ((Output) -> Void) async -> Result<Void, Failure>
			private let lock = Lock()
            private var task: Task<Void, Never>?

			init(
				subscriber: S,
                priority: TaskPriority?,
				operation: @escaping ((Output) -> Void) async -> Result<Void, Failure>
			) {
				self.subscriber = subscriber
                self.priority = priority
				self.operation = operation
			}

			func request(_ demand: Subscribers.Demand) {
                guard demand > 0 else { return }
                lock.lock()
                defer { lock.unlock() }
                guard task == nil else { return }
                task = Task(priority: priority) {
                    let (operation, subscriber) = lock.withLock { (self.operation, self.subscriber) }
                    guard let subscriber else { return }
					let result = await operation { output in
                        guard !Task.isCancelled else { return }
                        _ = subscriber.receive(output)
					}
                    
                    guard !Task.isCancelled else { return }
					self.cancel()

					switch result {
					case .success:
                        subscriber.receive(completion: .finished)
					case let .failure(error):
                        subscriber.receive(completion: .failure(error))
					}
				}
			}

			func cancel() {
				lock.lock()
                task?.cancel()
                task = nil
				subscriber = nil
				operation = { _ in .success(()) }
				lock.unlock()
			}
		}
	}
}

#if swift(>=6.0)
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
    init(
        priority: TaskPriority? = nil,
        operation: @escaping ((Output) -> Void) async throws(Failure) -> Void
    ) {
        self.init(priority: priority) { send in
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
    init(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws(Failure) -> Output
    ) {
        self.init(priority: priority) { send in
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
#else
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
	init(
        priority: TaskPriority? = nil,
        operation: @escaping ((Output) -> Void) async throws -> Void
    ) {
		self.init(priority: priority) { send in
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
	init(
        priority: TaskPriority? = nil,
        operation: @escaping () async throws -> Output
    ) {
		self.init(priority: priority) { send in
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
	init(
        priority: TaskPriority? = nil,
        operation: @escaping ((Output) -> Void) async -> Void
    ) {
		self.init(priority: priority) { send in
			await operation(send)
			return .success(())
		}
	}

	/// Creates a publisher from a non-throwing async operation with a single emission.
	init(
        priority: TaskPriority? = nil,
        operation: @escaping () async -> Output
    ) {
		self.init(priority: priority) { send in
			let output = await operation()
			send(output)
			return .success(())
		}
	}
}
#endif

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
