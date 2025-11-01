import Combine

extension Publisher {

    /// Converts a publisher into an endless publisher that never completes.
    public func endless() -> Publishers.Merge<Self, Empty<Output, Failure>> {
        merge(with: Empty(completeImmediately: false))
    }
}
