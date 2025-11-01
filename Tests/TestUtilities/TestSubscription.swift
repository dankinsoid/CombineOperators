import Combine

public final class TestSubscription: Subscription {

    public let onRequest: (Subscribers.Demand) -> Void

    public init(onRequest: @escaping (Subscribers.Demand) -> Void) {
        self.onRequest = onRequest
    }

    public convenience init(onRequest: @escaping () -> Void) {
        self.init { _ in onRequest() }
    }

    public func request(_ demand: Subscribers.Demand) {
        onRequest(demand)
    }

    public func cancel() {}
}
