import Combine
import Foundation

/// Scheduler that executes on main thread, optimized to avoid unnecessary dispatch.
///
/// If already on main thread, executes synchronously. Otherwise dispatches async.
///
/// ```swift
/// publisher.receive(on: MainScheduler.instance)
/// ```
public struct MainScheduler: Scheduler {

	public var now: DispatchQueue.SchedulerTimeType { DispatchQueue.main.now }
	public var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }

	public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
	public typealias SchedulerOptions = Void

	/// Shared main scheduler instance.
	public static let instance = MainScheduler()

	/// Schedules action on main thread. Executes synchronously if already on main.
	public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
		if Thread.isMainThread {
			action()
		} else {
			DispatchQueue.main.async {
				action()
			}
		}
	}

	/// Synchronously executes MainActor-isolated closure, respecting isolation.
	public func syncSchedule<T>(_ action: @MainActor () -> T) -> T {
		if Thread.isMainThread {
			return MainActor.assumeIsolated {
				action()
			}
		} else {
			return DispatchQueue.main.sync {
				action()
			}
		}
	}

	public func schedule(
        after date: DispatchQueue.SchedulerTimeType,
        tolerance: DispatchQueue.SchedulerTimeType.Stride,
        options: SchedulerOptions?, _ action: @escaping () -> Void
    ) {
		DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil, action)
	}

	public func schedule(
        after date: DispatchQueue.SchedulerTimeType,
        interval: DispatchQueue.SchedulerTimeType.Stride,
        tolerance: DispatchQueue.SchedulerTimeType.Stride,
        options: SchedulerOptions?,
        _ action: @escaping () -> Void
    ) -> any Cancellable {
		DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: nil, action)
	}
}
