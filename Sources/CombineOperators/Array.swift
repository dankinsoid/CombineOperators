//
//  File.swift
//  
//
//  Created by Данил Войдилов on 17.03.2021.
//

import Foundation
import Combine

extension Publishers {
	
	public struct Each<Upstream: Publisher>: Publisher where Upstream.Output: Collection {
		public typealias Output = [AnyPublisher<Upstream.Output.Element, Upstream.Failure>]
		public typealias Failure = Upstream.Failure
		public let upstream: Upstream
		
		public func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Output == S.Input {
			upstream
				.skipEqualSize()
				.map {
					Swift.zip($0, $0.indices).map {
						ElementAtIndex(index: $0.1, upstream: upstream).prepend($0.0).eraseToAnyPublisher()
					}
				}
				.withLast()
				.map {
					Each.takeLast($0)
				}
				.receive(subscriber: subscriber)
		}
		
		private static func takeLast<T>(_ args: ([T]?, [T])) -> [T] {
			if var prev = args.0 {
				if prev.count < args.1.count {
					prev.append(contentsOf: args.1[prev.count..<args.1.count])
				} else {
					prev.removeLast(prev.count - args.1.count)
				}
				return prev
			} else {
				return args.1
			}
		}
	}
	
	public struct ElementAtIndex<Upstream: Publisher>: Publisher where Upstream.Output: Collection {
		public typealias Output = Upstream.Output.Element
		public typealias Failure = Upstream.Failure
		public let index: Upstream.Output.Index
		public let upstream: Upstream
		
		public func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Upstream.Output.Element == S.Input {
			upstream.compactMap { value -> Output? in
				guard index >= value.startIndex, index < value.endIndex else { return nil }
				return value[index]
				
			}.receive(subscriber: subscriber)
		}
	}
}

extension Publisher where Output: Collection {
	
	public func each() -> Publishers.Each<Self> {
		Publishers.Each(upstream: self)
	}
	
	public func element(at index: Output.Index) -> Publishers.ElementAtIndex<Self> {
		Publishers.ElementAtIndex(index: index, upstream: self)
	}
}

extension Publisher {
	public func at(_ index: Int) -> Single<Output, Error> {
		dropFirst(index).prefix(1).asSingle()
	}
}
