//
//  File.swift
//  
//
//  Created by Данил Войдилов on 12.03.2021.
//

import Foundation
import Combine

public struct MainSyncScheduler: Scheduler {
	public var now: DispatchQueue.SchedulerTimeType { DispatchQueue.main.now }
	public var minimumTolerance: DispatchQueue.SchedulerTimeType.Stride { DispatchQueue.main.minimumTolerance }
	
	public init() {}
	
	public func schedule(options: Void?, _ action: @escaping () -> Void) {
		if Thread.isMainThread {
			action()
		} else {
			DispatchQueue.main.async(execute: action)
		}
	}
	
	public func schedule(after date: DispatchQueue.SchedulerTimeType, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: Void?, _ action: @escaping () -> Void) {
		DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: nil, action)
	}
	
	public func schedule(after date: DispatchQueue.SchedulerTimeType, interval: DispatchQueue.SchedulerTimeType.Stride, tolerance: DispatchQueue.SchedulerTimeType.Stride, options: Void?, _ action: @escaping () -> Void) -> Cancellable {
		DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: nil, action)
	}
}
