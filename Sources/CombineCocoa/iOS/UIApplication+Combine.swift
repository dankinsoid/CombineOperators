//
//  UIApplication+Combine.swift
//  CombineCocoa
//
//  Created by Mads Bøgeskov on 18/01/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import UIKit
import Combine

extension Reactive where Base: UIApplication {

	/// Emits when app enters background.
	///
	/// ```swift
	/// UIApplication.cb.didEnterBackground
	///     .sink { saveState() }
	/// ```
	public static var didEnterBackground: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
	/// Emits when app will enter foreground.
	public static var willEnterForeground: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when app finishes launching.
	public static var didFinishLaunching: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when app becomes active.
	public static var didBecomeActive: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when app will resign active state.
	public static var willResignActive: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when system issues memory warning.
	public static var didReceiveMemoryWarning: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when app will terminate.
	public static var willTerminate: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits on significant time change (midnight, timezone change, etc.).
	public static var significantTimeChange: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when background refresh status changes.
	public static var backgroundRefreshStatusDidChange: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.backgroundRefreshStatusDidChangeNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when protected data will become unavailable (device locks).
	public static var protectedDataWillBecomeUnavailable: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when protected data becomes available (device unlocks).
	public static var protectedDataDidBecomeAvailable: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification).map { _ in }

        return ControlEvent(events: source)
    }

	/// Emits when user takes screenshot.
	public static var userDidTakeScreenshot: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification).map { _ in }

        return ControlEvent(events: source)
    }
}
#endif
