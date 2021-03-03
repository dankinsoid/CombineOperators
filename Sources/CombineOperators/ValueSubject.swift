//
//  File.swift
//  
//
//  Created by Данил Войдилов on 03.03.2021.
//

import Foundation
import Combine

@propertyWrapper
public struct ValueSubject<Output> {
	public typealias Failure = Never
	public var wrappedValue: Output {
		get { projectedValue.value }
		nonmutating set { projectedValue.value = newValue }
	}
	public let projectedValue: CurrentValueSubject<Output, Never>
	
	public init(wrappedValue: Output) {
		projectedValue = CurrentValueSubject(wrappedValue)
	}
}
