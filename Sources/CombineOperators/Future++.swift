//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import Combine

extension Single {
	public func await() throws -> Output {
		var e: Output?
		var err: Failure?
		let semaphore = DispatchSemaphore(value: 0)
		var d: Cancellable?
		DispatchQueue.global().async {
			d = self.sink(
				receiveCompletion: {
					switch $0 {
					case .failure(let error):
						err = error
						semaphore.signal()
					case .finished:
						semaphore.signal()
					}
				},
				receiveValue: { element in
					e = element
				}
			)
		}
		semaphore.wait()
		d?.cancel()
		if let er = err {
			throw er
		} else if e == nil {
			throw CombineError.condition
		}
		return e!
	}
}

extension Single where Failure == Never {
	
	public func await() -> Output {
		var e: Output?
		let semaphore = DispatchSemaphore(value: 0)
		var d: Cancellable?
		DispatchQueue.global().async {
			d = self.sink(
				receiveCompletion: {
					switch $0 {
					case .failure:
						semaphore.signal()
					case .finished:
						semaphore.signal()
					}
				},
				receiveValue: { element in
					e = element
				}
			)
		}
		semaphore.wait()
		d?.cancel()
		return e!
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Future {
	
	public func await() throws -> Output {
		try asSingle().await()
	}
	
	//	public static func wrap(_ function: @escaping (@escaping (Result<Output, Failure>) -> Void) -> Void) -> Future {
	//		create { block -> Cancellable in
	//			function { block($0.mapError { $0 }) }
	//			return Cancellables.create()
	//		}
	//	}
	//
	//	public static func wrap<A>(_ function: @escaping (A, @escaping (Result<Output, Failure>) -> Void) -> Void, value: A) -> Single<Output> {
	//		wrap { function(value, $0) }
	//	}
	//
	//	public static func wrap<A, B>(_ function: @escaping (A, B, @escaping (Result<Output, Failure>) -> Void) -> Void, _ value1: A, _ value2: B) -> Single<Output> {
	//		wrap { function(value1, value2, $0) }
	//	}
	//
	//	public static func wrap<A, B, C>(_ function: @escaping (A, B, C, @escaping (Result<Output, Failure>) -> Void) -> Void, _ value1: A, _ value2: B, _ value3: C) -> Single<Output> {
	//		wrap { function(value1, value2, value3, $0) }
	//	}
	//
	//
	//	public static func guarantee(_ function: @escaping (@escaping (Output) -> Void) -> Void) -> Single<Output> {
	//		wrap { completion in function { completion(Result<Output, Never>.success($0)) } }
	//	}
	//
	//	public static func guarantee<A>(_ function: @escaping (A, @escaping (Output) -> Void) -> Void, value: A) -> Single<Output> {
	//		guarantee { function(value, $0) }
	//	}
	//
	//	public static func guarantee<A, B>(_ function: @escaping (A, B, @escaping (Output) -> Void) -> Void, _ value1: A, _ value2: B) -> Single<Output> {
	//		guarantee { function(value1, value2, $0) }
	//	}
	//
	//	public static func guarantee<A, B, C>(_ function: @escaping (A, B, C, @escaping (Output) -> Void) -> Void, _ value1: A, _ value2: B, _ value3: C) -> Single<Output> {
	//		guarantee { function(value1, value2, value3, $0) }
	//	}
	//
	//
	//	public static func wrap<Failure: Error>(_ function: @escaping (@escaping (Output, Failure?) -> Void) -> Void) -> Single<Output> {
	//		wrap { completion in function { completion(Result(success: $0, failure: $1)) } }
	//	}
	//
	//	public static func wrap<A, Failure: Error>(_ function: @escaping (A, @escaping (Output, Failure?) -> Void) -> Void, value: A) -> Single<Output> {
	//		wrap { function(value, $0) }
	//	}
	//
	//	public static func wrap<A, B, Failure: Error>(_ function: @escaping (A, B, @escaping (Output, Failure?) -> Void) -> Void, _ value1: A, _ value2: B) -> Single<Output> {
	//		wrap { function(value1, value2, $0) }
	//	}
	//
	//	public static func wrap<A, B, C, Failure: Error>(_ function: @escaping (A, B, C, @escaping (Output, Failure?) -> Void) -> Void, _ value1: A, _ value2: B, _ value3: C) -> Single<Output> {
	//		wrap { function(value1, value2, value3, $0) }
	//	}
	
}

//extension Result where Failure == Error {
//
//	public init(success: Success?, failure: Error?) {
//		if let value = success {
//			self = .success(value)
//		} else {
//			self = .failure(failure ?? UnknownError.unknown)
//		}
//	}
//
//}
