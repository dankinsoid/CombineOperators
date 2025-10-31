import Combine

public extension Subscriber where Failure == Error {

	/// Type-erases specific error to generic `Error`.
	func setFailureType<F: Error>(to: F.Type = F.self) -> Subscribers.MapFailure<Self, Error> {
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
}

/// Combines two subscribers to receive the same events.
///
/// Both subscribers receive all subscriptions, values, and completions.
/// Demand is the minimum of both subscribers' demands.
///
/// ```swift
/// let combined = subscriberA + subscriberB
/// ```
public func + <T: Subscriber, O: Subscriber>(_ lhs: T, _ rhs: O) -> AnySubscriber<O.Input, O.Failure> where O.Input == T.Input, O.Failure == T.Failure {
	AnySubscriber(
		receiveSubscription: {
			lhs.receive(subscription: $0)
			rhs.receive(subscription: $0)
		},
		receiveValue: {
			min(lhs.receive($0), rhs.receive($0))
		},
		receiveCompletion: {
			lhs.receive(completion: $0)
			rhs.receive(completion: $0)
		}
	)
}
