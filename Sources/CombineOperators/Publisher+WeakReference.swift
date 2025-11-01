import Combine
import Foundation

public extension Publisher {

	/// Combines output with a weak reference, completing when object deallocates.
	///
	/// ```swift
	/// viewModel.data
	///     .with(weak: self)
	///     .sink { (vc, data) in vc.display(data) }
	/// ```
    func with<T: AnyObject>(weak object: T?) -> some Publisher<(T, Output), Failure> {
        prefix(untilOutputFrom: Publishers.OnDeinit(object))
            .compactMap { [weak object] in
                guard let object else {
                    return nil
                }
                return (object, $0)
            }
    }
}

public extension Publisher where Output == Void {

	/// Emits weak reference for each void emission.
	///
	/// Completes when object deallocates.
    func with<T: AnyObject>(weak object: T?) -> some Publisher<T, Failure> {
        prefix(untilOutputFrom: Publishers.OnDeinit(object))
            .compactMap { [weak object] in object }
    }
}
