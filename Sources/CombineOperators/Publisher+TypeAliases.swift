import Foundation
import Combine

/// Alias for `CurrentValueSubject` that never fails.
public typealias ValueSubject<Output> = CurrentValueSubject<Output, Never>

extension Publishers {
    /// Typealias for publisher that emits (previous?, current) value pairs.
    public typealias WithLast<P: Publisher> = Map<Scan<P, (P.Output?, P.Output?)>, (P.Output?, P.Output)>
}
