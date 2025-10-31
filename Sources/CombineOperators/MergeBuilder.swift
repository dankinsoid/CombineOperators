import Combine

/// Result builder for merging multiple publishers declaratively.
///
/// ```swift
/// let merged = AnyPublisher<Int, Never>.merge {
///     publisher1
///     publisher2
///     if condition {
///         publisher3
///     }
///     [4, 5, 6]  // sequence as publisher
/// }
/// ```
@resultBuilder
public struct MergeBuilder<Output, Failure: Error> {

	@inline(__always)
	public static func buildArray(_ components: [AnyPublisher<Output, Failure>]) -> AnyPublisher<Output, Failure> {
		Publishers.MergeMany(components).eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildEither<P: Publisher>(first component: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component.eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildEither<P: Publisher>(second component: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component.eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildOptional<P: Publisher>(_ component: P?) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component?.eraseToAnyPublisher() ?? Empty(completeImmediately: true).eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildLimitedAvailability<P: Publisher>(second component: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		component.eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildBlock() -> AnyPublisher<Output, Failure> {
		Empty(completeImmediately: false).eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildBlock(_ components: AnyPublisher<Output, Failure>...) -> AnyPublisher<Output, Failure> {
		Publishers.MergeMany(components).eraseToAnyPublisher()
	}

	@inline(__always)
	public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Failure {
		expression.eraseToAnyPublisher()
	}

	public static func buildExpression(_ expression: Output) -> AnyPublisher<Output, Failure> {
		Just(expression).setFailureType(to: Failure.self).eraseToAnyPublisher()
	}

	public static func buildExpression(_ expression: [Output]) -> AnyPublisher<Output, Failure> {
		Publishers.Sequence(sequence: expression).eraseToAnyPublisher()
	}

	public static func buildExpression<A: Collection>(_ expression: A) -> AnyPublisher<Output, Failure> where A.Element: Publisher, A.Element.Output == Output, A.Element.Failure == Failure {
		Publishers.MergeMany(expression).eraseToAnyPublisher()
	}
}

public extension MergeBuilder where Failure == Error {

	static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output {
		expression.eraseFailure().eraseToAnyPublisher()
	}

	static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Error {
		expression.eraseToAnyPublisher()
	}
}

public extension MergeBuilder where Failure == Never {

	static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output {
		expression.skipFailure().eraseToAnyPublisher()
	}

	static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Never {
		expression.eraseToAnyPublisher()
	}
}

public extension AnyPublisher {

	/// Creates a merged publisher from multiple sources using result builder.
	///
	/// ```swift
	/// let merged = AnyPublisher<String, Never>.merge {
	///     textPublisher
	///     urlPublisher.map { $0.absoluteString }
	///     ["constant", "values"]
	/// }
	/// ```
	static func merge(@MergeBuilder<Output, Failure> _ build: () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
		build()
	}
}
