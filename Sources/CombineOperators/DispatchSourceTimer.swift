//
//  File.swift
//  
//
//  Created by Данил Войдилов on 04.03.2021.
//

import Foundation
import Combine

extension DispatchSource {
	
	public final class Timer {
		private var source: DispatchSourceTimer?
		public var flags: DispatchSource.TimerFlags
		public var queue: DispatchQueue?
		public var interval: DispatchTimeInterval
		public var leeway: DispatchTimeInterval
		private let deadline: () -> DispatchTime
		private(set) public var state: State = .suspended
		public var isCancelled: Bool { source?.isCancelled ?? false }
		private(set) public var step = 0
		public var count: Count
		private var wasSuspend = false
		
		public init(_ interval: DispatchTimeInterval, delay: @autoclosure @escaping () -> DispatchTime, count: Count = .infinite, leeway: DispatchTimeInterval = .never, flags: DispatchSource.TimerFlags = [], queue: DispatchQueue? = nil) {
			self.flags = flags
			self.queue = queue
			self.deadline = delay
			self.interval = count > 1 ? interval : .never
			self.leeway = leeway
			self.count = Swift.max(0, count)
		}
		
		public convenience init(_ interval: TimeInterval, delay: @autoclosure @escaping () -> DispatchTime = .now(), count: Count = .infinite, leeway: DispatchTimeInterval = .never, flags: DispatchSource.TimerFlags = [], queue: DispatchQueue? = nil) {
			self.init(
				.nanoseconds(Int(interval * 1_000_000_000)),
				delay: delay(),
				count: count,
				leeway: leeway,
				flags: flags,
				queue: queue
			)
		}
		
		public static func start(_ interval: DispatchTimeInterval, delay: @autoclosure @escaping () -> DispatchTime = .now(), count: Int, leeway: DispatchTimeInterval = .never, flags: DispatchSource.TimerFlags = [], queue: DispatchQueue? = nil, _ action: @escaping () -> Void) {
			var timer: Timer? = Timer(interval, delay: delay(), count: .finite(count), leeway: leeway, flags: flags, queue: queue)
			timer?.start {
				action()
				if let step = timer?.step, step >= count - 1 {
					(queue ?? .main).async {
						timer = nil
					}
				}
			}
		}

		public func start(_ action: @escaping () -> Void) {
			guard count > 0 else { return }
			cancel()
			source = DispatchSource.makeTimerSource(flags: flags, queue: queue)
			source?.schedule(deadline: deadline(), repeating: interval, leeway: leeway)
			source?.setEventHandler {[weak self] in
				guard let `self` = self else { return }
				guard Count.finite(self.step) < self.count else {
					(self.queue ?? .main).async {
						self.cancel()
					}
					return
				}
				action()
				self.step += 1
			}
			resume()
		}
		
		public func resume() {
			if state == .resumed {
				return
			}
			state = .resumed
			source?.resume()
		}
			
		public func suspend() {
			if state == .suspended {
				return
			}
			state = .suspended
			source?.suspend()
			wasSuspend = true
		}
		
		public func cancel() {
			step = 0
			source?.setEventHandler(handler: {})
			if wasSuspend {
				resume()
			}
			source?.cancel()
			source = nil
		}
		
		deinit {
			cancel()
		}
		
		public enum Count: ExpressibleByIntegerLiteral, Comparable {
			case infinite, finite(Int)
			
			public init(integerLiteral value: Int) {
				self = .finite(value)
			}
			
			public init(_ value: Int) {
				self = .finite(value)
			}
			
			public var value: Int? {
				if case .finite(let value) = self {
					return value
				}
				return nil
			}
			
			public static func < (lhs: Count, rhs: Count) -> Bool {
				switch (lhs, rhs) {
				case (.infinite, .infinite):						return false
				case (.infinite, .finite):							return false
				case (.finite, .infinite):							return true
				case (.finite(let l), .finite(let r)):	return l < r
				}
			}
		}
		
		public enum State {
			case suspended
			case resumed
		}
	}
}

extension DispatchSource.Timer: Combine.Publisher {
	public typealias Output = Date
	public typealias Failure = Never
	
	public func receive<S: Subscriber>(subscriber: S) where Never == S.Failure, Date == S.Input {
		subscriber.receive(subscription: TimerSubscription(self, subscriber: subscriber))
	}
	
	private final class TimerSubscription<S: Subscriber>: Subscription where S.Input == Output, S.Failure == Failure {
		var timer: DispatchSource.Timer
		let subscriber: S
		
		init(_ timer: DispatchSource.Timer, subscriber: S) {
			self.timer = timer
			self.subscriber = subscriber
		}
		
		func request(_ demand: Subscribers.Demand) {
			let owner = Owner()
			owner.timer = self
			timer.count = Swift.min(timer.count, demand.max.map(Count.finite) ?? .infinite)
			timer.start {[subscriber] in
				let count = subscriber.receive(Date())
				guard count > .none else {
					subscriber.receive(completion: .finished)
					(owner.timer?.timer.queue ?? .main).async {
						owner.timer?.cancel()
						owner.timer = nil
					}
					return
				}
				if let max = owner.timer?.timer.count.value, (owner.timer?.timer.step ?? -1) >= max - 1 {
					subscriber.receive(completion: .finished)
					(owner.timer?.timer.queue ?? .main).async {
						owner.timer?.cancel()
						owner.timer = nil
					}
				}
			}
		}
		
		func cancel() {
			timer.cancel()
		}
		
		private class Owner {
			var timer: TimerSubscription?
		}
	}
}
