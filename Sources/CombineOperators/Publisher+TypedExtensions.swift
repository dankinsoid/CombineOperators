import Foundation
import Combine

// MARK: - Bool Publishers

extension Publisher where Output == Bool {

	/// Inverts boolean values.
	///
	/// ```swift
	/// isVisible.toggle()  // false becomes true, true becomes false
	/// ```
	public func toggle() -> Publishers.Map<Self, Bool> {
		map { !$0 }
	}
}

// MARK: - Collection Publishers

extension Publisher where Output: Collection {

	/// Removes duplicates based on collection size.
	///
	/// Only emits when collection size changes.
	public func skipEqualSize() -> Publishers.RemoveDuplicates<Self> {
		removeDuplicates { $0.count == $1.count }
	}

	/// Maps collection to nil if empty, otherwise returns collection.
	public var nilIfEmpty: Publishers.Map<Self, Output?> {
		map { $0.isEmpty ? nil : $0 }
	}

	/// Maps collection to its isEmpty boolean.
	public var isEmpty: Publishers.Map<Self, Bool> {
		map { $0.isEmpty }
	}
}
