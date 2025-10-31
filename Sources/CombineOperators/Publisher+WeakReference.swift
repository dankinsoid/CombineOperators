import Foundation
import Combine

extension Publisher {

    /// Combines output with a weak reference, completing when object deallocates.
    ///
    /// ```swift
    /// viewModel.data
    ///     .with(weak: self)
    ///     .sink { (vc, data) in vc.display(data) }
    /// ```
    public func with<T: AnyObject>(weak object: T?) -> some Publisher<(T, Output), Failure> {
        map { [weak object] output in
            return (object, output)
        }
        .prefix(while: { $0.0 != nil })
        .compactMap {
            guard let object = $0.0 else {
                return nil
            }
            return (object, $0.1)
        }
    }
}

extension Publisher where Output == Void {

    /// Emits weak reference for each void emission.
    ///
    /// Completes when object deallocates.
    public func with<T: AnyObject>(weak object: T?) -> some Publisher<T, Failure> {
        map { [weak object] _ -> T? in object }
        .prefix { $0 != nil }
        .compactMap { $0 }
    }
}
