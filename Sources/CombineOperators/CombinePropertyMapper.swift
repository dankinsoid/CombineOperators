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
public struct CombinePropertyMapper<Base: Publisher, Output, Failure: Error>: Publisher {
	private let base: Base
	private let keyPath: KeyPath<Base.Output, Output>
	
	fileprivate init(_ base: Base, for keyPath: KeyPath<Base.Output, Output>) {
		self.base = base
		self.keyPath = keyPath
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Output, T>) -> CombinePropertyMapper<Base, T, Failure> {
		CombinePropertyMapper<Base, T, Failure>(base, for: self.keyPath.appending(path: keyPath))
	}
	
	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
		
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	public var mp: CombinePropertyMapper<Self, Output, Failure> { CombinePropertyMapper(self, for: \.self) }
}
