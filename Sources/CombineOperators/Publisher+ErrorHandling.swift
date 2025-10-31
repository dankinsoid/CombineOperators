import Combine
import Foundation

public extension Publisher {

	/// Ignores failures, completing silently on error.
	func skipFailure() -> Publishers.Catch<Self, Empty<Output, Never>> {
		self.catch { _ in Empty() }
	}

	/// Replaces any failure with a default value.
	///
	/// ```swift
	/// fetchData().catch(defaultData)
	/// ```
	func `catch`(_ just: Output) -> Publishers.Catch<Self, Just<Output>> {
		self.catch { _ in Just(just) }
	}

	/// Type-erases failure to generic `Error`.
	func eraseFailure() -> Publishers.MapError<Self, Error> {
		mapError { $0 as Error }
	}

	/// Converts publisher to Result type, never failing.
	///
	/// ```swift
	/// dataPublisher
	///     .asResult()
	///     .sink { result in
	///         switch result {
	///         case .success(let data): print(data)
	///         case .failure(let error): print(error)
	///         }
	///     }
	/// ```
	func asResult() -> some Publisher<Result<Output, Failure>, Never> {
		map { .success($0) }
			.catch { Just(.failure($0)) }
	}
}
