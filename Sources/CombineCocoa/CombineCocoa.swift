import Combine
@_exported import CombineOperators
import Foundation
#if os(iOS)
import UIKit
#endif

/// Errors that can occur during CombineCocoa operations.
///
/// These errors typically indicate programming errors (wrong property names,
/// type mismatches) rather than runtime failures.
///
/// ```swift
/// // Handling casting errors:
/// do {
///     let result: String = try castOrThrow(String.self, value)
/// } catch let error as CombineCocoaError {
///     print(error.debugDescription)
/// }
///
/// // KVO property name validation:
/// guard object.responds(to: Selector(propertyName)) else {
///     throw CombineCocoaError.invalidPropertyName(
///         object: object,
///         propertyName: propertyName
///     )
/// }
/// ```
public enum CombineCocoaError: Swift.Error, CustomDebugStringConvertible {
	/// Unknown error occurred.
	case unknown
	/// Invalid operation attempted on object.
	case invalidOperation(object: Any)
	/// Items not yet bound to UI when requested.
	case itemsNotYetBound(object: Any)
	/// Invalid KVO property name.
	case invalidPropertyName(object: Any, propertyName: String)
	/// Invalid object found on keypath.
	case invalidObjectOnKeyPath(object: Any, sourceObject: AnyObject, propertyName: String)
	/// Swizzling failed.
	case errorDuringSwizzling
	/// Type casting failed.
	case castingError(object: Any, targetType: Any.Type)
}

// MARK: Debug descriptions

public extension CombineCocoaError {
	/// A textual representation of `self`, suitable for debugging.
	var debugDescription: String {
		switch self {
		case .unknown:
			return "Unknown error occurred."
		case let .invalidOperation(object):
			return "Invalid operation was attempted on `\(object)`."
		case let .itemsNotYetBound(object):
			return "Data source is set, but items are not yet bound to user interface for `\(object)`."
		case let .invalidPropertyName(object, propertyName):
			return "Object `\(object)` doesn't have a property named `\(propertyName)`."
		case let .invalidObjectOnKeyPath(object, sourceObject, propertyName):
			return "Unobservable object `\(object)` was observed as `\(propertyName)` of `\(sourceObject)`."
		case .errorDuringSwizzling:
			return "Error during swizzling."
		case let .castingError(object, targetType):
			return "Error casting `\(object)` to `\(targetType)`"
		}
	}
}

// MARK: Error binding policies

/// Reports binding errors during runtime.
///
/// In DEBUG: triggers fatal error for immediate detection.
/// In RELEASE: prints error message and continues.
func bindingError(_ error: Swift.Error) {
	let error = "Binding error: \(error)"
	#if DEBUG
	rxFatalError(error)
	#else
	print(error)
	#endif
}

/// Enforces abstract method implementation in subclasses.
///
/// Call this from base class methods that must be overridden.
/// Always triggers fatal error.
func rxAbstractMethod(message: String = "Abstract method", file: StaticString = #file, line: UInt = #line) -> Swift.Never {
	rxFatalError(message, file: file, line: line)
}

func rxFatalError(_ lastMessage: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) -> Swift.Never {
	// The temptation to comment this line is great, but please don't, it's for your own good. The choice is yours.
	fatalError(lastMessage(), file: file, line: line)
}

/// Triggers fatal error in DEBUG, prints in RELEASE.
func rxFatalErrorInDebug(_ lastMessage: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
	#if DEBUG
	fatalError(lastMessage(), file: file, line: line)
	#else
	print("\(file):\(line): \(lastMessage())")
	#endif
}

// MARK: Type casting utilities

/// Casts optional value or crashes. Handles nil gracefully.
func castOptionalOrFatalError<T>(_ value: Any?) -> T? {
	if value == nil {
		return nil
	}
	let v: T = castOrFatalError(value)
	return v
}

/// Casts value to target type or throws `CombineCocoaError.castingError`.
func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
	guard let returnValue = object as? T else {
		throw CombineCocoaError.castingError(object: object, targetType: resultType)
	}

	return returnValue
}

/// Casts optional value or throws. Treats NSNull as nil.
func castOptionalOrThrow<T>(_ resultType: T.Type, _ object: AnyObject) throws -> T? {
	if NSNull().isEqual(object) {
		return nil
	}

	guard let returnValue = object as? T else {
		throw CombineCocoaError.castingError(object: object, targetType: resultType)
	}

	return returnValue
}

/// Casts value or crashes with custom message.
func castOrFatalError<T>(_ value: AnyObject!, message: String) -> T {
	let maybeResult: T? = value as? T
	guard let result = maybeResult else {
		rxFatalError(message)
	}

	return result
}

/// Casts value or crashes with generated message.
func castOrFatalError<T>(_ value: Any!) -> T {
	let maybeResult: T? = value as? T
	guard let result = maybeResult else {
		rxFatalError("Failure converting from \(String(describing: value)) to \(T.self)")
	}

	return result
}

// MARK: Error messages

let dataSourceNotSet = "DataSource not set"
let delegateNotSet = "Delegate not set"

// MARK: Shared with CombineSwift

func rxFatalError(_ lastMessage: String) -> Never {
	// The temptation to comment this line is great, but please don't, it's for your own good. The choice is yours.
	fatalError(lastMessage)
}

func cbFatalError(_ lastMessage: String) -> Never {
	fatalError(lastMessage)
}
