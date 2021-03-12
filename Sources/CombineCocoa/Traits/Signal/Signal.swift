//
//  Signal.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 9/26/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Foundation
import Combine
import CombineOperators

/**
 Trait that represents observable sequence with following properties:
 
 - it never fails
 - it delivers events on `MainScheduler.instance`
 - `share(scope: .whileConnected)` sharing strategy

 Additional explanation:
 - all observers share sequence computation resources
 - there is no replaying of sequence elements on new observer subscription
 - computation of elements is reference counted with respect to the number of observers
 - if there are no subscribers, it will release sequence computation resources

 In case trait that models state propagation is required, please check `Driver`.

 `Signal<Element>` can be considered a builder pattern for observable sequences that model imperative events part of the application.
 
 To find out more about units and how to use them, please visit `Documentation/Traits.md`.
 */

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	
	public func asSignal() -> Signal<Output> {
		Signal(self.skipFailure())
	}
	
	public func asSignal(replaceError: Output) -> Signal<Output> {
		Signal(self) { _ in Just(replaceError) }
	}
	
	public func asSignal<C: Publisher>(catch handler: @escaping (Error) -> C) -> Signal<Output> where C.Output == Output {
		Signal(self, catch: handler)
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
public struct Signal<Output>: Publisher {
	public typealias Failure = Never
	private let publisher: AnyPublisher<Output, Failure>
	
	public init<P: Publisher, C: Publisher>(_ source: P, catch handler: @escaping (Error) -> C) where C.Output == P.Output, C.Output == Output {
		self = Signal(source.catch(handler).skipFailure())
	}
	
	public init<P: Publisher>(_ source: P) where Never == P.Failure, P.Output == Output {
		publisher = source.share().receive(on: MainSyncScheduler()).eraseToAnyPublisher()
	}
	
	public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
		publisher.receive(subscriber: subscriber)
	}
}
