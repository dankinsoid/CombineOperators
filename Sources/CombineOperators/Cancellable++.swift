import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
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
		from.count == 1 ? from[0] : AnyCancellable(from)
	}
}

@available(iOS 13.0, macOS 10.15, *)
extension AnyCancellable {
	
	public convenience init(_ list: Cancellable...) {
		self.init(list)
	}
	
	public convenience init(_ list: [Cancellable]) {
		self.init {
			list.forEach { $0.cancel() }
		}
	}
}
