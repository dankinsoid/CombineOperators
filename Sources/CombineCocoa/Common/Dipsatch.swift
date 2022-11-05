import Foundation

extension DispatchQueue {
	
	public class func ensureRunningOnMainThread(errorMessage: String? = nil) {
		#if !os(Linux) // isMainThread is not implemented in Linux Foundation
		guard Thread.isMainThread else {
			rxFatalError(errorMessage ?? "Running on background thread.")
		}
		#endif
	}
	
	public class func onMainIfNeeded(_ block: @escaping () -> Void) {
		#if !os(Linux) // isMainThread is not implemented in Linux Foundation
		guard Thread.isMainThread else {
			DispatchQueue.main.async(execute: block)
			return
		}
		block()
		#endif
	}
}
