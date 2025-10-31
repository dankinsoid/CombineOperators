import Combine
import Foundation

/// Alias for `CurrentValueSubject` that never fails.
public typealias ValueSubject<Output> = CurrentValueSubject<Output, Never>

public extension Publishers {
	/// Typealias for publisher that emits (previous?, current) value pairs.
	typealias WithLast<P: Publisher> = Map<Scan<P, (P.Output?, P.Output?)>, (P.Output?, P.Output)>
}
