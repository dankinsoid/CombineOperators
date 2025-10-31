import Combine

extension Subscriber where Failure == Error {

    public func setFailureType<F: Error>(to: F.Type = F.self) -> Subscribers.MapFailure<Self, Error> {
        mapFailure { $0 as Error }
    }
}

extension Subscriber {

    public func map<NewInput>(_ transform: @escaping (NewInput) -> Input) -> Subscribers.Map<Self, NewInput> {
        Subscribers.Map<Self, NewInput>(self, transform: transform)
    }

    public func mapFailure<NewFailure: Error>(_ transform: @escaping (NewFailure) -> Failure) -> Subscribers.MapFailure<Self, NewFailure> {
        Subscribers.MapFailure<Self, NewFailure>(self, transform: transform)
    }

    public func nonFailing() -> Subscribers.MapFailure<Self, Never> {
        mapFailure { never in
            never
        }
    }

    public func nonOptional<T>() -> Subscribers.Map<Self, T> where Input == T? {
        map { $0 }
    }
}

extension Subscribers {
    
    public struct Map<Base: Subscriber, NewInput>: Subscriber {
        
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

    public struct MapFailure<Base: Subscriber, NewFailure: Error>: Subscriber {
        
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
            return base.receive(input)
        }
        
        public func receive(completion: Subscribers.Completion<NewFailure>) {
           switch completion {
            case .finished:
                base.receive(completion: .finished)
            case .failure(let error):
                let newError = transform(error)
                base.receive(completion: .failure(newError))
            }
        }
    }
}

public func +<T: Subscriber, O: Subscriber>(_ lhs: T, _ rhs: O) -> AnySubscriber<O.Input, O.Failure> where O.Input == T.Input, O.Failure == T.Failure {
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
