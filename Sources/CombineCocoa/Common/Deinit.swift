import Combine
import Foundation

public extension Reactive where Base: AnyObject {

	/// A publisher that emits a value when the object is deinitialized.
	var onDeinit: Publishers.OnDeinit {
		Publishers.OnDeinit(base)
	}
}
