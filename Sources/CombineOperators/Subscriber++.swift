import Combine

public extension Subscriber where Failure == Error {

	/// Type-erases specific error to generic `Error`.
	func setFailureType<F: Error>(to: F.Type = F.self) -> Subscribers.MapFailure<Self, F> {
		mapFailure { $0 as Error }
	}
}

public extension Subscriber {

	/// Transforms incoming values before they reach this subscriber.
	///
	/// ```swift
	/// subscriber.map { (string: String) in Int(string) ?? 0 }
	/// ```
	func map<NewInput>(_ transform: @escaping (NewInput) -> Input) -> Subscribers.Map<Self, NewInput> {
		Subscribers.Map<Self, NewInput>(self, transform: transform)
	}

	/// Transforms incoming failures before they reach this subscriber.
	func mapFailure<NewFailure: Error>(_ transform: @escaping (NewFailure) -> Failure) -> Subscribers.MapFailure<Self, NewFailure> {
		Subscribers.MapFailure<Self, NewFailure>(self, transform: transform)
	}

	/// Performs an action when a completion event is received.
	func onCompletion(_ action: @escaping (Subscribers.Completion<Failure>) -> Void) -> Subscribers.OnCompletion<Self> {
		Subscribers.OnCompletion<Self>(self, action: action)
	}

	/// Converts to a non-failing subscriber (Never failure type).
	func nonFailing() -> Subscribers.MapFailure<Self, Never> {
		mapFailure { never in
			never
		}
	}

	/// Unwraps optional input type.
	func nonOptional<T>() -> Subscribers.Map<Self, T> where Input == T? {
		map { $0 }
	}
}

public extension Subscribers {

	struct Map<Base: Subscriber, NewInput>: Subscriber {

		public typealias Input = NewInput
		public typealias Failure = Base.Failure

		public var combineIdentifier: CombineIdentifier {
			base.combineIdentifier
		}

		private let base: Base
		private let transform: (NewInput) -> Base.Input

		public init(_ base: Base, transform: @escaping (NewInput) -> Base.Input) {
			self.base = base
			self.transform = transform
		}

		public func receive(subscription: Subscription) {
			base.receive(subscription: subscription)
		}

		public func receive(_ input: NewInput) -> Subscribers.Demand {
			let newInput = transform(input)
			return base.receive(newInput)
		}

		public func receive(completion: Subscribers.Completion<Failure>) {
			base.receive(completion: completion)
		}
	}

	struct MapFailure<Base: Subscriber, NewFailure: Error>: Subscriber {

		public typealias Input = Base.Input
		public typealias Failure = NewFailure

		public var combineIdentifier: CombineIdentifier {
			base.combineIdentifier
		}

		private let base: Base
		private let transform: (NewFailure) -> Base.Failure

		public init(_ base: Base, transform: @escaping (NewFailure) -> Base.Failure) {
			self.base = base
			self.transform = transform
		}

		public func receive(subscription: Subscription) {
			base.receive(subscription: subscription)
		}

		public func receive(_ input: Input) -> Subscribers.Demand {
			base.receive(input)
		}

		public func receive(completion: Subscribers.Completion<NewFailure>) {
			switch completion {
			case .finished:
				base.receive(completion: .finished)
			case let .failure(error):
				let newError = transform(error)
				base.receive(completion: .failure(newError))
			}
		}
	}

	struct OnCompletion<Base: Subscriber>: Subscriber {

		public typealias Input = Base.Input
		public typealias Failure = Base.Failure

		public var combineIdentifier: CombineIdentifier {
			base.combineIdentifier
		}

		private let base: Base
		private let action: (Subscribers.Completion<Failure>) -> Void

		public init(_ base: Base, action: @escaping (Subscribers.Completion<Failure>) -> Void) {
			self.base = base
			self.action = action
		}

		public func receive(subscription: Subscription) {
			base.receive(subscription: subscription)
		}

		public func receive(_ input: Input) -> Subscribers.Demand {
			base.receive(input)
		}

		public func receive(completion: Subscribers.Completion<Failure>) {
			action(completion)
			base.receive(completion: completion)
		}
	}
}
