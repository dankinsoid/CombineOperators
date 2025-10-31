#if os(iOS)

import Combine
import UIKit

public extension Reactive where Base: UIApplication {

	/// Emits when app enters background.
	///
	/// ```swift
	/// UIApplication.cb.didEnterBackground
	///     .sink { saveState() }
	/// ```
	static var didEnterBackground: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when app will enter foreground.
	static var willEnterForeground: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when app finishes launching.
	static var didFinishLaunching: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when app becomes active.
	static var didBecomeActive: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when app will resign active state.
	static var willResignActive: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when system issues memory warning.
	static var didReceiveMemoryWarning: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when app will terminate.
	static var willTerminate: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits on significant time change (midnight, timezone change, etc.).
	static var significantTimeChange: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when background refresh status changes.
	static var backgroundRefreshStatusDidChange: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.backgroundRefreshStatusDidChangeNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when protected data will become unavailable (device locks).
	static var protectedDataWillBecomeUnavailable: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when protected data becomes available (device unlocks).
	static var protectedDataDidBecomeAvailable: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification).map { _ in }

		return ControlEvent(events: source)
	}

	/// Emits when user takes screenshot.
	static var userDidTakeScreenshot: ControlEvent<Void> {
		let source = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification).map { _ in }

		return ControlEvent(events: source)
	}
}
#endif
