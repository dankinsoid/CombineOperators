//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import VDKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension Publisher {
	
	public func smooth<F: FloatingPoint>(
		_ duration: TimeInterval = 1,
		float: @escaping (Output) -> F,
		value: @escaping (F, Output) -> Output,
		runLoop: RunLoop = .main,
		condition: @escaping (Output, Output) -> Bool = { _, _ in true }
	) -> some Publisher {
		let interval: TimeInterval = 20.0 / 1000
		return smooth(interval: interval, count: Int(duration / interval), runLoop: runLoop, float: float, value: value, condition: condition)
	}
	
	public func smooth<F: FloatingPoint>(interval: TimeInterval, count: Int, runLoop: RunLoop = .main, float: @escaping (Output) -> F, value: @escaping (F, Output) -> Output, condition: @escaping (Output, Output) -> Bool = { _, _ in true }) -> some Publisher {
		smooth(
			rule: { f, s, count in
				let (first, second) = (float(f), float(s))
				let isGrow = first < second
				let range = isGrow ? first...second : second...first
				return (isGrow ? range.split(count: count) : range.split(count: count).reversed()).map { value($0, s) }
			},
			interval: interval,
			count: count,
			runLoop: runLoop,
			condition: condition
		)
	}
	
	public func smooth(rule: @escaping (Output, Output, Int) -> [Output], interval: TimeInterval, count: Int, runLoop: RunLoop = .main, condition: @escaping (Output, Output) -> Bool = { _, _ in true }) -> some Publisher {
		scan([]) { $0.suffix(1) + [$1] }
			.flat { (list: [Output]) -> AnyPublisher<Output, Never> in
				guard list.count == 2 else { return Just(list[0]).eraseToAnyPublisher() }
				guard condition(list[0], list[1]) else { return Just(list[1]).eraseToAnyPublisher() }
				let array = rule(list[0], list[1], count)
				return Timer.TimerPublisher(interval: interval, runLoop: runLoop, mode: .default).autoconnect()
					.zip(Publishers.Sequence(sequence: array))
					.map { $0.1 }
					.eraseToAnyPublisher()
			}
	}
	
	public func smooth(rule: @escaping (Output, Output, Int) -> [Output], duration: TimeInterval = 1, runLoop: RunLoop = .main, condition: @escaping (Output, Output) -> Bool = { _, _ in true }) -> some Publisher {
		let interval: TimeInterval = 20.0 / 1000
		return smooth(rule: rule, interval: interval, count: Int(duration / interval), runLoop: runLoop, condition: condition)
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output: FloatingPoint {
	
	public func smooth(_ duration: TimeInterval = 1, runLoop: RunLoop = .main) -> some Publisher {
		let interval: TimeInterval = 20 / 1000
		return smooth(interval: interval, count: Int(duration / interval), runLoop: runLoop)
	}
	
	public func smooth(interval: TimeInterval, count: Int, runLoop: RunLoop = .main) -> some Publisher {
		removeDuplicates()
			.smooth(
				rule: {
					let isGrow = $0 < $1
					let range = isGrow ? $0...$1 : $1...$0
					return isGrow ? range.split(count: $2) : range.split(count: $2).reversed()
				},
				interval: interval,
				count: count,
				runLoop: runLoop
			)
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Publisher where Output == String {
	
	public func smooth(_ duration: TimeInterval = 0.3, runLoop: RunLoop = .main) -> some Publisher {
		let interval: TimeInterval = 30 / 1000
		return smooth(interval: interval, count: Int(duration / interval), runLoop: runLoop)
	}
	
	public func smooth(interval: TimeInterval, count: Int, runLoop: RunLoop = .main) -> some Publisher {
		removeDuplicates()
			.smooth(
				rule: {
					$0.smooth(to: $1, count: $2)
				},
				interval: interval,
				count: count,
				runLoop: runLoop
			)
	}
	
}

extension String {
	
	func smooth(to: String, count: Int) -> [String] {
		guard count > 2 else { return [self, to].suffix(max(0, count)) }
		guard !to.isEmpty || !isEmpty else {
			return [String](repeating: "", count: count)
		}
		guard to != self else {
			return [String](repeating: to, count: count)
		}
		var result = [self]
		let commonPr = commonPrefix(with: to)
		let commonSfCount = max(0, min(commonSuffix(with: to).count, min(self.count, to.count) - commonPr.count))
		for i in commonPr.count..<(max(self.count, to.count) - commonSfCount) {
			var last = result[result.count - 1]
			if i < last.count, i < to.count {
				last[.first + i] = to[.first + i]
			} else if i < to.count {
				last.append(to[.first + i]!)
			} else if i < last.count {
				_ = last.remove(at: .first + i)
			}
			result.append(last)
		}
		if result.count < count {
			for _ in 0..<(count - result.count) {
				let i = Int.random(in: 0..<result.count)
				result.insert(result[i], at: i)
			}
		} else if count < result.count {
			for _ in 0..<(result.count - count) {
				result.remove(at: .random(in: 0..<result.count))
			}
		}
		result[result.count - 1] = to
		return result
	}
	
	func commonSuffix(with aString: String) -> String {
		var suffix = ""
		var first = self
		var second = aString
		while let symbol = first.last, !second.isEmpty, first.last == second.last {
			first.removeLast()
			second.removeLast()
			suffix.insert(symbol, at: suffix.startIndex)
		}
		return suffix
	}
	
}

extension ClosedRange where Bound: FloatingPoint {
	
	public func split(count: Int) -> [Bound] {
		guard count > 2 else { return [lowerBound, upperBound].suffix(count) }
		var result: [Bound] = [lowerBound]
		let delta = (upperBound - lowerBound) / Bound(count)
		for _ in 2..<count {
			result.append(result[result.count - 1] + delta)
		}
		result.append(upperBound)
		return result
	}
	
}

@available(iOS 13.0, macOS 10.15, *)
extension Timer.TimerPublisher {
	
	public convenience init(_ interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop = .current, mode: RunLoop.Mode = .default, options: RunLoop.SchedulerOptions? = nil) {
		self.init(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode, options: options)
	}
	
}
