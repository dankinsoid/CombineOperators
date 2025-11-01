import Combine

final class TestSubscription: Subscription {
    
    let onRequest: (Subscribers.Demand) -> Void

    init(onRequest: @escaping (Subscribers.Demand) -> Void) {
        self.onRequest = onRequest
    }
    
    convenience init(onRequest: @escaping () -> Void) {
        self.init { _ in onRequest() }
    }

    func request(_ demand: Subscribers.Demand) {
        onRequest(demand)
    }

    func cancel() {}
}
