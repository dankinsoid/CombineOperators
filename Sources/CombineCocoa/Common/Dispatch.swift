import Foundation

extension DispatchQueue {
	
	public class func ensureRunningOnMainThread(errorMessage: String? = nil) {
		#if !os(Linux) // isMainThread is not implemented in Linux Foundation
		guard Thread.isMainThread else {
			rxFatalError(errorMessage ?? "Running on background thread.")
		}
		#endif
	}
}
