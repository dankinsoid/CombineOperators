import Combine

public final class TestSubscriber<Input, Failure: Error>: Subscriber {

    public var demand: Subscribers.Demand
	private let onValue: (Input) -> Void
	private let additionalDemand: ((Int) -> Subscribers.Demand)?
    private let onCompletion: (Subscribers.Completion<Failure>) -> Void
	private let onSubscription: ((Subscription) -> Void)?
	private var receiveCount = 0

	public init(
        demand: Subscribers.Demand = .unlimited,
        onValue: @escaping (Input) -> Void = { _ in },
        onError: @escaping (Failure) -> Void = { _ in },
        onFinished: @escaping () -> Void = {},
		additionalDemand: ((Int) -> Subscribers.Demand)? = nil,
		onSubscription: ((Subscription) -> Void)? = nil
	) {
		self.demand = demand
		self.onValue = onValue
		self.additionalDemand = additionalDemand
		self.onSubscription = onSubscription
        self.onCompletion = {
            switch $0 {
            case .failure(let error):
                onError(error)
            case .finished:
                onFinished()
            }
        }
	}

	public func receive(subscription: Subscription) {
		onSubscription?(subscription)
		subscription.request(demand)
	}

	public func receive(_ input: Input) -> Subscribers.Demand {
		guard demand > .none else { return .none }

		onValue(input)
		receiveCount += 1

        let result = additionalDemand?(receiveCount) ?? .none

		if demand != .unlimited {
            demand += result
			demand -= 1
		}

		return result
	}

	public func receive(completion: Subscribers.Completion<Failure>) {
        onCompletion(completion)
    }
}
