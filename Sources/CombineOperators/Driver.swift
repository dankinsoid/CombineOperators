import Foundation
import Combine

extension Publisher {
	
    /// Converts publisher to a UI-safe Driver with replay and main thread delivery.
    ///
    /// Properties:
    /// - Delivers on main thread
    /// - Shares computation (reference-counted)
    /// - Replays last value to new subscribers
    /// - Releases resources when all subscribers are gone
    ///
    /// ```swift
    /// let driver = URLSession.shared
    ///     .dataTaskPublisher(for: url)
    ///     .map(\.data)
    ///     .asDriver()
    ///
    /// // Multiple UI subscriptions share the same network request
    /// driver.assign(to: \.image, on: imageView)
    /// driver.map { $0.count }.assign(to: \.text, on: label)
    /// ```
	public func asDriver() -> some Publisher<Output, Failure> {
        share(replay: 1).receive(on: MainScheduler.instance)
	}
}
