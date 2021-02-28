//
//  File.swift
//  
//
//  Created by Данил Войдилов on 01.03.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
public final class ReplaySubject<Output, Failure: Error>: Subject {
	private var recording = Record<Output, Failure>.Recording()
	private let stream = PassthroughSubject<Output, Failure>()
	private let maxValues: Int
	
	public init(maxValues: Int = 0) {
		self.maxValues = maxValues
	}
	
	public func send(subscription: Subscription) {
		subscription.request(maxValues == 0 ? .unlimited : .max(maxValues))
	}
	
	public func send(_ value: Output) {
		recording.receive(value)
		stream.send(value)
		if recording.output.count == maxValues {
			send(completion: .finished)
		}
	}
	
	public func send(completion: Subscribers.Completion<Failure>) {
		recording.receive(completion: completion)
		stream.send(completion: completion)
	}
	
	public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		Record(recording: self.recording)
			.append(self.stream)
			.receive(subscriber: subscriber)
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	public func share(replay maxValues: Int = 0) -> AnyPublisher<Output, Failure> {
		multicast(subject: ReplaySubject(maxValues: maxValues)).autoconnect().eraseToAnyPublisher()
	}
}
