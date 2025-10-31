import Foundation
import Combine

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// CombineCocoa URL errors.
public enum CombineCocoaURLError: Swift.Error {
    /// Unknown error occurred.
    case unknown
    /// Response is not NSHTTPURLResponse
    case nonHTTPResponse(response: URLResponse)
    /// Response is not successful. (not in `200 ..< 300` range)
    case httpRequestFailed(response: URLResponse, data: Data?)
    /// Deserialization error.
    case deserializationError(error: Swift.Error)
}

extension CombineCocoaURLError: CustomDebugStringConvertible {
    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        switch self {
        case .unknown:
            return "Unknown error has occurred."
        case let .nonHTTPResponse(response):
            return "Response is not NSHTTPURLResponse `\(response)`."
        case let .httpRequestFailed(response, _):
            return "HTTP request failed with `\(response._statusCode ?? -1)`."
        case let .deserializationError(error):
            return "Error during deserialization of the response: \(error)"
        }
    }
}

extension Reactive where Base: URLSession {
	/// Publisher for URL request responses (data + URLResponse pair).
	///
	/// Request starts on subscription. Each subscriber triggers separate request.
	///
	/// ```swift
	/// urlSession.cb.response(request: request)
	///     .sink { print($0.data, $0.response) }
	/// ```
	public func response(request: URLRequest) -> URLSession.DataTaskPublisher {
		base.dataTaskPublisher(for: request)
	}

	/// Publisher for URL request data. Fails on non-2xx HTTP status codes.
	///
	/// Request starts on subscription. Each subscriber triggers separate request.
	///
	/// Throws `CombineCocoaURLError.httpRequestFailed` for status codes outside `200..<300`.
	public func data(request: URLRequest) -> AnyPublisher<Data, Error> {
			self.response(request: request).tryMap { pair -> Data in
				if 200 ..< 300 ~= (pair.1._statusCode ?? 201) {
					return pair.0
				}
				else {
					throw CombineCocoaURLError.httpRequestFailed(response: pair.1, data: pair.0)
				}
			}
			.eraseToAnyPublisher()
    }

	/// Publisher for URL request JSON. Fails on non-2xx status or invalid JSON.
	///
	/// Request starts on subscription. Each subscriber triggers separate request.
	///
	/// Throws `CombineCocoaURLError.httpRequestFailed` or `.deserializationError`.
	public func json(request: URLRequest, options: JSONSerialization.ReadingOptions = []) -> AnyPublisher<Any, Error> {
			self.data(request: request).tryMap { data -> Any in
				do {
					return try JSONSerialization.jsonObject(with: data, options: options)
				} catch let error {
					throw CombineCocoaURLError.deserializationError(error: error)
				}
			}
			.eraseToAnyPublisher()
    }

	/// Publisher for GET request JSON from URL.
	///
	/// Convenience wrapper for `json(request:)` with GET request.
	public func json(url: Foundation.URL) -> AnyPublisher<Any, Error> {
			self.json(request: URLRequest(url: url))
    }
}
extension Reactive where Base == URLSession {
    /// Log URL requests to standard output in curl format.
    public static var shouldLogRequest: (URLRequest) -> Bool = { _ in
			#if DEBUG
			return true
			#else
			return false
			#endif
    }
}

extension URLResponse {
	var _statusCode: Int? {
		(self as? HTTPURLResponse)?.statusCode
	}
}
