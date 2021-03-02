//
//  File.swift
//  
//
//  Created by Данил Войдилов on 02.03.2021.
//

import Foundation
import Combine

public struct Single<Output, Failure: Error>: Publisher {
	fileprivate let future: AnyPublisher<Output, Failure>
	
	public init(_ attemptToFulFill: @escaping (Future<Output, Failure>.Promise) -> Void, onCancel: @escaping () -> Void) {
		future = Deferred {
			Future(attemptToFulFill).onCancel(onCancel)
		}.any()
	}
	
	public init(_ attemptToFulFill: @escaping (Future<Output, Failure>.Promise) -> Void) {
		future = Deferred {
			Future(attemptToFulFill)
		}.any()
	}
	
	public init(_ action: @escaping () -> Result<Output, Failure>) {
		future = Deferred {
			Future { promise in
				promise(action())
			}
		}.any()
	}
	
	public init<P: Publisher>(_ publisher: P, ifEmpty: P.Failure) where P.Output == Output, P.Failure == Failure {
		future = publisher
			.prefix(1)
			.collect(1)
			.flatMap { list -> Result<Output, Failure>.Publisher in
				if list.count == 1 {
					return Result.Publisher(.success(list[0]))
				} else {
					return Result.Publisher(.failure(ifEmpty))
				}
			}
			.any()
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
		future.receive(subscriber: subscriber)
	}
	
	public static func just(_ element: Output) -> Single {
		Single {
			$0(.success(element))
		}
	}
	
	public static func fail(_ error: Failure) -> Single {
		Single {
			$0(.failure(error))
		}
	}
	
	public static func result(_ result: Result<Output, Failure>) -> Single {
		Single {
			result
		}
	}
}

extension Single where Failure == Error {
	
	public init<P: Publisher>(_ publisher: P) where P.Output == Output {
		self = Single(publisher.simpleError(), ifEmpty: CombineError.noElements)
	}
	
	public init(_ action: @escaping () throws -> Output) {
		future = Deferred {
			Future { promise in
				promise(Result(catching: action))
			}
		}.any()
	}
}

extension Single where Failure == Never {
	
	public init(_ action: @escaping () -> Output) {
		future = Deferred {
			Just(action())
		}.any()
	}
	
}

extension Single where Output == Void {
	public static func just() -> Single {
		Single {
			$0(.success)
		}
	}
}

extension Publisher {
	
	public func asSingle() -> Single<Output, Error> {
		Single(self)
	}
	
	public func asSingle(ifEmpty: Failure) -> Single<Output, Failure> {
		Single(self, ifEmpty: ifEmpty)
	}
}
