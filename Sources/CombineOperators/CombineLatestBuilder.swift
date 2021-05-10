//
//  File.swift
//  
//
//  Created by Данил Войдилов on 01.03.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
@resultBuilder
public struct CombineLatestBuilder {
	
	@_alwaysEmitIntoClient
	public static func buildBlock() -> Empty<Void, Never> {
		Empty()
	}
	
	@_alwaysEmitIntoClient
	public static func buildBlock<C0: Publisher>(_ c0: C0) -> C0 {
		c0
	}
	
	@_alwaysEmitIntoClient
	public static func buildBlock<C0: Publisher, C1: Publisher>(_ c0: C0, _ c1: C1) -> Publishers.CombineLatest<C0, C1> {
		c0.combineLatest(c1)
	}
	
	@_alwaysEmitIntoClient
	public static func buildBlock<C0: Publisher, C1: Publisher, C2: Publisher>(_ c0: C0, _ c1: C1, _ c2: C2) -> Publishers.CombineLatest3<C0, C1, C2> {
		c0.combineLatest(c1, c2)
	}
	
	@_alwaysEmitIntoClient
	public static func buildBlock<C0: Publisher, C1: Publisher, C2: Publisher, C3: Publisher>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> Publishers.CombineLatest4<C0, C1, C2, C3> {
		c0.combineLatest(c1, c2, c3)
	}
	
	@_alwaysEmitIntoClient
	public static func buildEither<P: Publisher>(first component: P) -> AnyPublisher<P.Output, P.Failure> {
		component.eraseToAnyPublisher()
	}
	
	@_alwaysEmitIntoClient
	public static func buildEither<P: Publisher>(second component: P) -> AnyPublisher<P.Output, P.Failure> {
		component.eraseToAnyPublisher()
	}
	
	public static func buildOptional<P: Publisher>(_ component: P?) -> AnyPublisher<P.Output, P.Failure> {
		component?.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
	}
	
	public static func buildLimitedAvailability<P: Publisher>(_ component: P) -> P {
		component
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Publishers {
	
	public static func combineLatest<P: Publisher>(@CombineLatestBuilder _ build: () -> P) -> P {
		build()
	}
	
}
