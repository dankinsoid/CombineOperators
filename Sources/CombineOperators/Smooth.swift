import Combine
import Foundation

/// Animates value transitions between emissions by interpolating intermediate values.
///
/// The `smooth` operators split value changes into multiple emissions over time,
/// creating smooth transitions. Specialized versions exist for `FloatingPoint` and `String` types.
public extension Publisher {

	/// Animates transitions between values using a custom interpolation strategy.
	///
	/// Transitions occur over the specified duration at 50fps (20ms intervals).
	/// The `condition` closure determines whether to animate a transition.
	///
	/// - Parameters:
	///   - duration: Total animation duration in seconds. Default is 1 second.
	///   - float: Extracts a numeric value from Output for interpolation.
	///   - value: Reconstructs Output from an interpolated numeric value.
	///   - runLoop: RunLoop for scheduling intermediate emissions. Default is `.main`.
	///   - condition: Returns `true` if transition should animate. Default always animates.
	///
	/// ```swift
	/// struct Model { var progress: Double }
	///
	/// publisher
	///     .smooth(
	///         0.5,
	///         float: \.progress,
	///         value: { Model(progress: $0) }
	///     )
	/// ```
	func smooth<F: FloatingPoint>(
		_ duration: TimeInterval = 1,
		float: @escaping (Output) -> F,
		value: @escaping (F, Output) -> Output,
		runLoop: RunLoop = .main,
		condition: @escaping (Output, Output) -> Bool = { _, _ in true }
	) -> AnyPublisher<Output, Failure> {
		let interval: TimeInterval = 20.0 / 1000
		return smooth(
			interval: interval,
			count: Int(duration / interval),
			runLoop: runLoop,
			float: float,
			value: value,
			condition: condition
		)
	}

	/// Animates transitions with explicit control over frame rate and count.
	///
	/// Lower-level variant that specifies exact timing parameters instead of duration.
	///
	/// - Parameters:
	///   - interval: Time between intermediate emissions.
	///   - count: Number of intermediate values to emit.
	///   - runLoop: RunLoop for scheduling intermediate emissions. Default is `.main`.
	///   - float: Extracts a numeric value from Output for interpolation.
	///   - value: Reconstructs Output from an interpolated numeric value.
	///   - condition: Returns `true` if transition should animate. Default always animates.
	func smooth<F: FloatingPoint>(
		interval: TimeInterval,
		count: Int,
		runLoop: RunLoop = .main,
		float: @escaping (Output) -> F,
		value: @escaping (F, Output) -> Output,
		condition: @escaping (Output, Output) -> Bool = { _, _ in true }
	) -> AnyPublisher<Output, Failure> {
		smooth(
			rule: { f, s, count in
				let (first, second) = (float(f), float(s))
				let isGrow = first < second
				let range = isGrow ? first ... second : second ... first
				return (isGrow ? range.split(count: count) : range.split(count: count).reversed()).map { value($0, s) }
			},
			interval: interval,
			count: count,
			runLoop: runLoop,
			condition: condition
		)
	}

	/// Animates transitions using a custom interpolation rule.
	///
	/// Most flexible variant that delegates interpolation logic to the `rule` closure.
	///
	/// - Parameters:
	///   - rule: Generates intermediate values between two emissions. Receives previous value, next value, and count.
	///   - interval: Time between intermediate emissions.
	///   - count: Number of intermediate values to generate.
	///   - runLoop: RunLoop for scheduling intermediate emissions. Default is `.main`.
	///   - condition: Returns `true` if transition should animate. Default always animates.
	func smooth(
		rule: @escaping (Output, Output, Int) -> [Output],
		interval: TimeInterval,
		count: Int,
		runLoop: RunLoop = .main,
		condition: @escaping (Output, Output) -> Bool = { _, _ in true }
	) -> AnyPublisher<Output, Failure> {
		scan([]) { $0.suffix(1) + [$1] }
			.flatMap { (list: [Output]) -> AnyPublisher<Output, Failure> in
				guard list.count == 2 else { return Just(list[0]).setFailureType(to: Failure.self).eraseToAnyPublisher() }
				guard condition(list[0], list[1]) else { return Just(list[1]).setFailureType(to: Failure.self).eraseToAnyPublisher() }
				let array = rule(list[0], list[1], count)
				return Timer.TimerPublisher(interval: interval, runLoop: runLoop, mode: .default)
					.autoconnect()
					.zip(Publishers.Sequence(sequence: array))
					.map { $0.1 }
					.setFailureType(to: Failure.self)
					.eraseToAnyPublisher()
			}
			.any()
	}

	/// Animates transitions using a custom rule with duration-based timing.
	///
	/// Convenience variant that calculates frame count from duration at 50fps.
	///
	/// - Parameters:
	///   - rule: Generates intermediate values between two emissions.
	///   - duration: Total animation duration in seconds. Default is 1 second.
	///   - runLoop: RunLoop for scheduling intermediate emissions. Default is `.main`.
	///   - condition: Returns `true` if transition should animate. Default always animates.
	func smooth(
		rule: @escaping (Output, Output, Int) -> [Output],
		duration: TimeInterval = 1,
		runLoop: RunLoop = .main,
		condition: @escaping (Output, Output) -> Bool = { _, _ in true }
	) -> AnyPublisher<Output, Failure> {
		let interval: TimeInterval = 20.0 / 1000
		return smooth(rule: rule, interval: interval, count: Int(duration / interval), runLoop: runLoop, condition: condition)
	}
}

/// Smooth transitions for numeric values.
public extension Publisher where Output: FloatingPoint {

	/// Animates numeric transitions with linear interpolation.
	///
	/// Automatically removes duplicate values before animating at 50fps.
	///
	/// ```swift
	/// Just(10.0)
	///     .smooth(0.5)  // Smoothly transitions over 0.5 seconds
	/// ```
	func smooth(_ duration: TimeInterval = 1, runLoop: RunLoop = .main) -> AnyPublisher<Output, Failure> {
		let interval: TimeInterval = 20 / 1000
		return smooth(interval: interval, count: Int(duration / interval), runLoop: runLoop)
	}

	/// Animates numeric transitions with explicit frame control.
	func smooth(interval: TimeInterval, count: Int, runLoop: RunLoop = .main) -> AnyPublisher<Output, Failure> {
		removeDuplicates()
			.smooth(
				rule: {
					let isGrow = $0 < $1
					let range = isGrow ? $0 ... $1 : $1 ... $0
					return isGrow ? range.split(count: $2) : range.split(count: $2).reversed()
				},
				interval: interval,
				count: count,
				runLoop: runLoop
			)
	}
}

/// Smooth transitions for text values.
///
/// Animates string changes by morphing characters at the prefix/suffix boundaries,
/// creating a typing effect.
public extension Publisher where Output == String {

	/// Animates string transitions character-by-character.
	///
	/// Preserves common prefix/suffix and morphs the middle section.
	/// Default duration is 0.3 seconds at ~33fps (30ms intervals).
	///
	/// ```swift
	/// textPublisher
	///     .smooth(0.5)  // Smooth typing effect
	/// ```
	func smooth(_ duration: TimeInterval = 0.3, runLoop: RunLoop = .main) -> AnyPublisher<Output, Failure> {
		let interval: TimeInterval = 30 / 1000
		return smooth(interval: interval, count: Int(duration / interval), runLoop: runLoop)
	}

	/// Animates string transitions with explicit frame control.
	func smooth(interval: TimeInterval, count: Int, runLoop: RunLoop = .main) -> AnyPublisher<Output, Failure> {
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
		for i in commonPr.count ..< (max(self.count, to.count) - commonSfCount) {
			var last = result[result.count - 1]
			if i < last.count, i < to.count {
				let index = last.index(last.startIndex, offsetBy: i)
				last.replaceSubrange(index ..< last.index(after: index), with: [to[to.index(to.startIndex, offsetBy: i)]])
			} else if i < to.count {
				last.append(to[to.index(to.startIndex, offsetBy: i)])
			} else if i < last.count {
				_ = last.remove(at: last.index(last.startIndex, offsetBy: i))
			}
			result.append(last)
		}
		if result.count < count {
			for _ in 0 ..< (count - result.count) {
				let i = Int.random(in: 0 ..< result.count)
				result.insert(result[i], at: i)
			}
		} else if count < result.count {
			for _ in 0 ..< (result.count - count) {
				result.remove(at: .random(in: 0 ..< result.count))
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

	func split(count: Int) -> [Bound] {
		guard count > 2 else { return [lowerBound, upperBound].suffix(count) }
		var result: [Bound] = [lowerBound]
		let delta = (upperBound - lowerBound) / Bound(count)
		for _ in 2 ..< count {
			result.append(result[result.count - 1] + delta)
		}
		result.append(upperBound)
		return result
	}
}

public extension Timer.TimerPublisher {

	convenience init(_ interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop = .current, mode: RunLoop.Mode = .default, options: RunLoop.SchedulerOptions? = nil) {
		self.init(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode, options: options)
	}
}
