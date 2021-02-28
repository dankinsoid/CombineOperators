//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
@dynamicMemberLookup
public struct CombinePropertyMapper<Base: Publisher, Output>: Publisher {
	public typealias Failure = Base.Failure
	private let base: Base
	private let keyPath: KeyPath<Base.Output, Output>
	
	fileprivate init(_ base: Base, for keyPath: KeyPath<Base.Output, Output>) {
		self.base = base
		self.keyPath = keyPath
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> CombinePropertyMapper<Base, T> {
		CombinePropertyMapper<Base, T>(base, for: self.keyPath.appending(path: keyPath))
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
		base.map(keyPath).receive(subscriber: subscriber)
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	public var mp: CombinePropertyMapper<Self, Output> { CombinePropertyMapper(self, for: \.self) }
}
