import Foundation
import Combine

@resultBuilder
public struct CancellableBuilder {
	
	@inlinable
	public static func buildBlock(_ components: Cancellable...) -> Cancellable {
		create(from: components)
	}
	
	@inlinable
	public static func buildArray(_ components: [Cancellable]) -> Cancellable {
		create(from: components)
	}
	
	@inlinable
	public static func buildEither(first component: Cancellable) -> Cancellable {
		component
	}
	
	@inlinable
	public static func buildEither(second component: Cancellable) -> Cancellable {
		component
	}
	
	@inlinable
	public static func buildOptional(_ component: Cancellable?) -> Cancellable {
		component ?? create(from: [])
	}
	
	@inlinable
	public static func buildLimitedAvailability(_ component: Cancellable) -> Cancellable {
		component
	}
	
	@inlinable
	public static func buildExpression(_ expression: Cancellable) -> Cancellable {
		expression
	}
	
	@inlinable
	public static func create(from: [Cancellable]) -> Cancellable {
		from.count == 1 ? from[0] : ManualAnyCancellable(from)
	}
}

extension AnyCancellable {
	
	public convenience init(_ list: Cancellable...) {
		self.init(list)
	}
	
    public convenience init(@CancellableBuilder _ builder: () -> Cancellable) {
        self.init(builder())
	}
    
    public convenience init<S: Sequence>(_ sequence: S) where S.Element == Cancellable {
        self.init {
            sequence.forEach { $0.cancel() }
        }
    }
}

public func +(_ lhs: Cancellable, _ rhs: Cancellable) -> Cancellable {
    ManualAnyCancellable(lhs, rhs)
}

public struct ManualAnyCancellable: Cancellable {

    private let cancelAction: () -> Void
    
    public init() {
        self.cancelAction = {}
    }

    public init(_ cancelAction: @escaping () -> Void) {
        self.cancelAction = cancelAction
    }
    
    public init(_ cancellables: Cancellable...) {
        self.init(cancellables)
    }

    public init<S: Sequence>(_ sequence: S) where S.Element == Cancellable {
        self.cancelAction = {
            sequence.forEach { $0.cancel() }
        }
    }

    public func cancel() {
        cancelAction()
    }
}
