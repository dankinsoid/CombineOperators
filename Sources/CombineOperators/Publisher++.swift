import Foundation
import Combine

public typealias ValueSubject<Output> = CurrentValueSubject<Output, Never>

extension Publisher {

    public func with<T: AnyObject>(weak object: T?) -> some Publisher<(T, Output), Failure> {
        map { [weak object] output in
            return (object, output)
        }
        .prefix(while: { $0.0 != nil })
        .compactMap {
            guard let object = $0.0 else {
                return nil
            }
            return (object, $0.1)
        }
    }

	public func skipFailure() -> Publishers.Catch<Self, Empty<Output, Never>> {
		self.catch { _ in Empty() }
	}

	public func `catch`(_ just: Output) -> Publishers.Catch<Self, Just<Output>> {
		self.catch { _ in Just(just) }
	}

	public func eraseFailure() -> Publishers.MapError<Self, Error> {
		mapError { $0 as Error }
	}

    public func interval(_ period: TimeInterval, runLoop: RunLoop = .main) -> AnyPublisher<Output, Never> {
        skipFailure()
            .zip(
                Timer.TimerPublisher(interval: period, runLoop: runLoop, mode: .default)
                    .autoconnect()
                    .prepend(Date())
            )
            .map { $0.0 }
            .eraseToAnyPublisher()
    }

	public func withLast(initial value: Output) -> Publishers.Scan<Self, (previous: Output, current: Output)> {
		scan((value, value)) { ($0.1, $1) }
	}

	public func withLast() -> Publishers.WithLast<Self> {
		scan((nil, nil)) { ($0.1, $1) }.map { ($0.0, $0.1!) }
	}

	public func value<T>(_ value: T) -> Publishers.Map<Self, T> {
		map { _ in value }
	}
	
	@inlinable
	public func any() -> AnyPublisher<Output, Failure> {
		eraseToAnyPublisher()
	}

	public func asResult() -> some Publisher<Result<Output, Failure>, Never> {
		map { .success($0) }
			.catch { Just(.failure($0)) }
	}

	public func append(_ values: Output...) -> Publishers.Concatenate<Self, Publishers.Sequence<[Output], Failure>> {
		append(Publishers.Sequence(sequence: values))
	}

	public func andIsSame<T: Equatable>(_ keyPath: KeyPath<Output, T>) -> Publishers.Map<Publishers.WithLast<Self>, (Self.Output, Bool)> {
		withLast().map {
			($0.1, $0.0?[keyPath: keyPath] == $0.1[keyPath: keyPath])
		}
	}

	public func onValue(_ action: @escaping (Output) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveOutput: action)
	}

	public func onFailure(_ action: @escaping (Failure) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .failure(let error) = $0 {
				action(error)
			}
		})
	}

	public func onFinished(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCompletion: {
			if case .finished = $0 {
				action()
			}
		})
	}

	public func onSubscribe(_ action: @escaping (Subscription) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveSubscription: action)
	}

	public func onCancel(_ action: @escaping () -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveCancel: action)
	}

	public func onRequest(_ action: @escaping (Subscribers.Demand) -> Void) -> Publishers.HandleEvents<Self> {
		handleEvents(receiveRequest: action)
	}
}

extension Publisher {

	public func isNil<T>() -> Publishers.Map<Self, Bool> where Output == T? {
		map { $0 == nil }
	}

	public func skipNil<T>() -> Publishers.SkipNil<Self, T> where Output == T? {
		Publishers.SkipNil(source: self)
	}

	public func or<T>(_ value: T) -> Publishers.Map<Self, T> where Output == T? {
		map { $0 ?? value }
	}

    public func optional() -> Publishers.Map<Self, Output?> {
        map { $0 }
    }
}

extension Publisher where Output == Bool {

	public func toggle() -> Publishers.Map<Self, Bool> {
		map { !$0 }
	}
}

extension Publisher where Output == Void {

    public func with<T: AnyObject>(weak object: T?) -> some Publisher<T, Failure> {
        map { [weak object] _ -> T? in object }
        .prefix { $0 != nil }
        .compactMap { $0 }
    }
}

extension Publisher where Output: Collection {

	public func skipEqualSize() -> Publishers.RemoveDuplicates<Self> {
		removeDuplicates { $0.count == $1.count }
	}
	public var nilIfEmpty: Publishers.Map<Self, Output?> { map { $0.isEmpty ? nil : $0 } }
	public var isEmpty: Publishers.Map<Self, Bool> { map { $0.isEmpty } }
}

extension Publisher {

	public func isNilOrEmpty<T: Collection>() -> Publishers.Map<Self, Bool> where Output == T? {
		map { $0?.isEmpty != false }
	}
}

extension Publishers {

	public typealias WithLast<P: Publisher> = Map<Scan<P, (P.Output?, P.Output?)>, (P.Output?, P.Output)>

	public struct SkipNil<P: Publisher, Output>: Publisher where P.Output == Output? {

		public typealias Failure = P.Failure
		public let source: P

		public func receive<S: Subscriber>(subscriber: S) where P.Failure == S.Failure, Output == S.Input {
			source.compactMap { $0 }.receive(subscriber: subscriber)
		}
	}
}

extension AnyPublisher {
	
	public static func just(_ value: Output) -> AnyPublisher {
		Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
	}
	
    public static var never: AnyPublisher {
		Empty(completeImmediately: false).eraseToAnyPublisher()
	}
	
	public static func from(_ values: Output...) -> AnyPublisher {
		from(values)
	}
	
	public static func from<S: Sequence>(_ values: S) -> AnyPublisher where S.Element == Output {
		Publishers.Sequence(sequence: values).eraseToAnyPublisher()
	}
	
	public static func failure(_ failure: Failure) -> AnyPublisher {
		Result.Publisher(.failure(failure)).eraseToAnyPublisher()
	}
	
    public static var empty: AnyPublisher {
		Empty(completeImmediately: true).eraseToAnyPublisher()
	}
}

public prefix func !<O: Publisher>(_ rhs: O) -> Publishers.Map<O, Bool> where O.Output == Bool {
    rhs.map { !$0 }
}

public func +<T: Publisher, O: Publisher>(_ lhs: T, _ rhs: O) -> Publishers.Merge<T, O> where O.Output == T.Output, O.Failure == T.Failure {
    lhs.merge(with: rhs)
}

public func ?? <O: Publisher, T>(_ lhs: O, _ rhs: @escaping @autoclosure () -> T) -> Publishers.Map<O, T> where O.Output == T? {
    lhs.map { $0 ?? rhs() }
}

public func &<T1: Publisher, T2: Publisher>(_ lhs: T1, _ rhs: T2) -> Publishers.CombineLatest<T1, T2> where T1.Failure == T2.Failure { lhs.combineLatest(rhs) }
