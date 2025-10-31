import Combine

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

extension MergeBuilder where Failure == Error {

    public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output {
        expression.eraseFailure().eraseToAnyPublisher()
    }

    public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Error {
        expression.eraseToAnyPublisher()
    }
}

extension MergeBuilder where Failure == Never {
    
    public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output {
        expression.skipFailure().eraseToAnyPublisher()
    }
    
    public static func buildExpression<P: Publisher>(_ expression: P) -> AnyPublisher<Output, Failure> where P.Output == Output, P.Failure == Never {
        expression.eraseToAnyPublisher()
    }
}

extension AnyPublisher {

    public static func merge(@MergeBuilder<Output, Failure> _ build: () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
        build()
    }
}
