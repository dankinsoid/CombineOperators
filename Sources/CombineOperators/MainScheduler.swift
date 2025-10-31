import Foundation
import Combine

public struct MainScheduler: Scheduler {

    public var now: DispatchQueue.SchedulerTimeType { DispatchQueue.main.now }
    public var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }
    
    public typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    public typealias SchedulerOptions = Void
    
    public static let instance = MainScheduler()
    
    public func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async {
                action()
            }
        }
    }
    
    public func synchSchedule<T>(_ action: @MainActor () -> T) -> T {
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

    public func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil, action)
    }
    
    public func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> any Cancellable {
        DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: nil, action)
    }
}
