//
//  Infallible+Bind.swift
//  CombineCocoa
//
//  Created by Shai Mishali on 27/08/2020.
//  Copyright © 2020 Krunoslav Zaher. All rights reserved.
//

import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Failure == Never {
    /**
     Creates new subscription and sends elements to observer(s).
     In this form, it's equivalent to the `subscribe` method, but it better conveys intent, and enables
     writing more consistent binding code.
     - parameter to: Observers to receives events.
     - returns: Cancellable object that can be used to unsubscribe the observers.
     */
	public func bind<Observer: Subscriber>(to observers: Observer...) where Observer.Input == Output, Observer.Failure == Failure {
			subscribe(Observers(observers: observers))
    }

    /**
     Creates new subscription and sends elements to observer(s).
     In this form, it's equivalent to the `subscribe` method, but it better conveys intent, and enables
     writing more consistent binding code.
     - parameter to: Observers to receives events.
     - returns: Cancellable object that can be used to unsubscribe the observers.
     */
    public func bind<Observer: Subscriber>(to observers: Observer...) where Observer.Input == Output?, Observer.Failure == Failure {
        self.map { $0 as Output? }
					.subscribe(Observers(observers: observers))
    }

    /**
    Subscribes to observable sequence using custom binder function.

    - parameter to: Function used to bind elements from `self`.
    - returns: Object representing subscription.
    */
    public func bind<Result>(to binder: (Self) -> Result) -> Result {
        binder(self)
    }

    /**
    Subscribes to observable sequence using custom binder function and final parameter passed to binder function
    after `self` is passed.

        public func bind<R1, R2>(to binder: Self -> R1 -> R2, curriedArgument: R1) -> R2 {
            return binder(self)(curriedArgument)
        }

    - parameter to: Function used to bind elements from `self`.
    - parameter curriedArgument: Final argument passed to `binder` to finish binding process.
    - returns: Object representing subscription.
    */
    public func bind<R1, R2>(to binder: (Self) -> (R1) -> R2, curriedArgument: R1) -> R2 {
        binder(self)(curriedArgument)
    }


//    /**
//    Creates new subscription and sends elements to `BehaviorRelay`.
//
//    - parameter relay: Target relay for sequence elements.
//    - returns: Cancellable object that can be used to unsubscribe the observer from the relay.
//    */
//    public func bind(to relays: BehaviorRelay<Output>...) -> Cancellable {
//        return self.subscribe(onNext: { e in
//            relays.forEach { $0.accept(e) }
//        })
//    }
//
//    /**
//     Creates new subscription and sends elements to `BehaviorRelay`.
//
//     - parameter relay: Target relay for sequence elements.
//     - returns: Cancellable object that can be used to unsubscribe the observer from the relay.
//     */
//    public func bind(to relays: BehaviorRelay<Output?>...) -> Cancellable {
//        return self.subscribe(onNext: { e in
//            relays.forEach { $0.accept(e) }
//        })
//    }
//
//    /**
//    Creates new subscription and sends elements to `PublishRelay`.
//
//    - parameter relay: Target relay for sequence elements.
//    - returns: Cancellable object that can be used to unsubscribe the observer from the relay.
//    */
//    public func bind(to relays: PublishRelay<Output>...) -> Cancellable {
//        return self.subscribe(onNext: { e in
//            relays.forEach { $0.accept(e) }
//        })
//    }
//
//    /**
//     Creates new subscription and sends elements to `PublishRelay`.
//
//     - parameter relay: Target relay for sequence elements.
//     - returns: Cancellable object that can be used to unsubscribe the observer from the relay.
//     */
//    public func bind(to relays: PublishRelay<Output?>...) -> Cancellable {
//        return self.subscribe(onNext: { e in
//            relays.forEach { $0.accept(e) }
//        })
//    }
//
//    /**
//    Creates new subscription and sends elements to `ReplayRelay`.
//
//    - parameter relay: Target relay for sequence elements.
//    - returns: Cancellable object that can be used to unsubscribe the observer from the relay.
//    */
//    public func bind(to relays: ReplayRelay<Output>...) -> Cancellable {
//        return self.subscribe(onNext: { e in
//            relays.forEach { $0.accept(e) }
//        })
//    }
//
//    /**
//     Creates new subscription and sends elements to `ReplayRelay`.
//
//     - parameter relay: Target relay for sequence elements.
//     - returns: Cancellable object that can be used to unsubscribe the observer from the relay.
//     */
//    public func bind(to relays: ReplayRelay<Output?>...) -> Cancellable {
//        return self.subscribe(onNext: { e in
//            relays.forEach { $0.accept(e) }
//        })
//    }
}
