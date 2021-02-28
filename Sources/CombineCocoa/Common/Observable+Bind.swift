//
//  Publisher+Bind.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 8/29/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
    /**
     Creates new subscription and sends elements to observer(s).
     In this form, it's equivalent to the `subscribe` method, but it better conveys intent, and enables
     writing more consistent binding code.
     - parameter to: Observers to receives events.
     - returns: Cancellable object that can be used to unsubscribe the observers.
     */
	public func bind<Observer: Subscriber>(to observers: Observer...) where Observer.Input == Output, Observer.Failure == Failure {
        self.subscribe(Observers(observers: observers))
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
    
    /**
    Subscribes an element handler to an observable sequence.
    In case error occurs in debug mode, `fatalError` will be raised.
    In case error occurs in release mode, `error` will be logged.

     - Note: If `object` can't be retained, none of the other closures will be invoked.
     
    - parameter object: The object to provide an unretained reference on.
    - parameter onNext: Action to invoke for each element in the observable sequence.
    - returns: Subscription object used to unsubscribe from the observable sequence.
    */
    public func bind<Object: AnyObject>(
        with object: Object,
        _ onNext: @escaping (Object, Output) -> Void
    ) -> Cancellable {
			self.sink(
				receiveCompletion: { completion in
					if case .failure(let error) = completion {
						rxFatalErrorInDebug("Binding error: \(error)")
					}
				},
				receiveValue: { [weak object] in
					guard let object = object else { return }
					onNext(object, $0)
				})
    }
    
    /**
    Subscribes an element handler to an observable sequence.
    In case error occurs in debug mode, `fatalError` will be raised.
    In case error occurs in release mode, `error` will be logged.

    - parameter onNext: Action to invoke for each element in the observable sequence.
    - returns: Subscription object used to unsubscribe from the observable sequence.
    */
	public func bind(_ onNext: @escaping (Output) -> Void) -> Cancellable {
		sink(
			receiveCompletion: { completion in
				if case .failure(let error) = completion {
					rxFatalErrorInDebug("Binding error: \(error)")
				}
			},
			receiveValue: onNext
		)
	}
	
}
