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

extension Array: Cancellable where Element == Cancellable {
	public func cancel() {
		forEach { $0.cancel() }
	}
}

public final class CancellableBag: Cancellable, RangeReplaceableCollection {
	public typealias Element = AnyCancellable
	private var bag = Set<AnyCancellable>()
	public var startIndex: Set<AnyCancellable>.Index { bag.startIndex }
	public var endIndex: Set<AnyCancellable>.Index { bag.endIndex }
	
	public init() {}
	
	public subscript(position: Set<AnyCancellable>.Index) -> AnyCancellable {
		bag[position]
	}
	
	public func index(after i: Set<AnyCancellable>.Index) -> Set<AnyCancellable>.Index {
		bag.index(after: i)
	}
	
	public func cancel() {
		bag.removeAll()
	}
	
}

public struct CancellablePublisher: Cancellable, Publisher {
	public typealias Output = Void
	public typealias Failure = Never
	private let subject = CurrentValueSubject<Void?, Never>(nil)
	public var isCancelled: Bool {
		subject.value != nil
	}
	
	public init() {}
	
	public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
		subject.skipNil().prefix(1).receive(subscriber: subscriber)
	}
	
	public func cancel() {
		subject.send(())
	}
}
