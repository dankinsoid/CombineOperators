import Foundation

extension DispatchQueue {

	/// Asserts that code is executing on the main thread.
	///
	/// Fatal error if called from background thread (except on Linux where check is unavailable).
	public class func ensureRunningOnMainThread(errorMessage: String? = nil) {
		#if !os(Linux) // isMainThread is not implemented in Linux Foundation
		guard Thread.isMainThread else {
			rxFatalError(errorMessage ?? "Running on background thread.")
		}
		#endif
	}
}
