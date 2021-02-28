//
//  File.swift
//  
//
//  Created by Данил Войдилов on 27.02.2021.
//

import Foundation

extension NSRecursiveLock {
	@inline(__always)
	final func performLocked<T>(_ action: () -> T) -> T {
		self.lock(); defer { self.unlock() }
		return action()
	}
}
