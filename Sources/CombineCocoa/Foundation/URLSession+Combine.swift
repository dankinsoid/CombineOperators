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
    /**
    Publisher sequence of responses for URL request.
    
    Performing of request starts after observer is subscribed and not after invoking this method.
    
    **URL requests will be performed per subscribed observer.**
    
    Any error during fetching of the response will cause observed sequence to terminate with error.
    
    - parameter request: URL request.
    - returns: Publisher sequence of URL responses.
    */
	public func response(request: URLRequest) -> URLSession.DataTaskPublisher {
		base.dataTaskPublisher(for: request)
	}

    /**
    Publisher sequence of response data for URL request.
    
    Performing of request starts after observer is subscribed and not after invoking this method.
    
    **URL requests will be performed per subscribed observer.**
    
    Any error during fetching of the response will cause observed sequence to terminate with error.
    
    If response is not HTTP response with status code in the range of `200 ..< 300`, sequence
    will terminate with `(CombineCocoaErrorDomain, CombineCocoaError.NetworkError)`.
    
    - parameter request: URL request.
    - returns: Publisher sequence of response data.
    */
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

    /**
    Publisher sequence of response JSON for URL request.
    
    Performing of request starts after observer is subscribed and not after invoking this method.
    
    **URL requests will be performed per subscribed observer.**
    
    Any error during fetching of the response will cause observed sequence to terminate with error.
    
    If response is not HTTP response with status code in the range of `200 ..< 300`, sequence
    will terminate with `(CombineCocoaErrorDomain, CombineCocoaError.NetworkError)`.
    
    If there is an error during JSON deserialization observable sequence will fail with that error.
    
    - parameter request: URL request.
    - returns: Publisher sequence of response JSON.
    */
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

    /**
    Publisher sequence of response JSON for GET request with `URL`.
     
    Performing of request starts after observer is subscribed and not after invoking this method.
    
    **URL requests will be performed per subscribed observer.**
    
    Any error during fetching of the response will cause observed sequence to terminate with error.
    
    If response is not HTTP response with status code in the range of `200 ..< 300`, sequence
    will terminate with `(CombineCocoaErrorDomain, CombineCocoaError.NetworkError)`.
    
    If there is an error during JSON deserialization observable sequence will fail with that error.
    
    - parameter url: URL of `NSURLRequest` request.
    - returns: Publisher sequence of response JSON.
    */
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
