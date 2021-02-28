//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import VDKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
public typealias CancellableBuilder = ComposeBuilder<CancellableCreator>

@available(iOS 13.0, macOS 10.15, *)
public struct CancellableCreator: ArrayInitable {
	public static func create(from: [Cancellable]) -> Cancellable {
		from.count == 1 ? from[0] : AnyCancellable(from)
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension ComposeBuilder where C == CancellableCreator {
	
	@inlinable
	public static func buildExpression(_ expression: Cancellable) -> Cancellable {
		expression
	}
	
	@inlinable
	public static func buildExpression(_ expression: Void) -> Cancellable {
		AnyCancellable()
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension AnyCancellable {
	
	public convenience init() {
		self.init({})
	}
	
	public convenience init(_ list: Cancellable...) {
		self.init(list)
	}
	
	public convenience init(_ list: [Cancellable]) {
		self.init {
			list.forEach { $0.cancel() }
		}
	}
	
	public static func build(@CancellableBuilder _ builder: () -> Cancellable) -> AnyCancellable {
		AnyCancellable(builder())
	}
	
}
