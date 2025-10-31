import Foundation

/// Internal errors used by Combine operators.
enum CombineError: Error {
	/// Condition not met
	case condition
	/// Sequence was empty when element was required
	case noElements
	/// Unspecified error
	case unknown
}
