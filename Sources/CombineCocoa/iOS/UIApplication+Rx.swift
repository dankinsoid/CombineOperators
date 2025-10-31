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
    
    /// Reactive wrapper for `UIApplication.didEnterBackgroundNotification`
    public static var didEnterBackground: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.willEnterForegroundNotification`
    public static var willEnterForeground: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.didFinishLaunchingNotification`
    public static var didFinishLaunching: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didFinishLaunchingNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.didBecomeActiveNotification`
    public static var didBecomeActive: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.willResignActiveNotification`
    public static var willResignActive: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.didReceiveMemoryWarningNotification`
    public static var didReceiveMemoryWarning: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.willTerminateNotification`
    public static var willTerminate: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.significantTimeChangeNotification`
    public static var significantTimeChange: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.backgroundRefreshStatusDidChangeNotification`
    public static var backgroundRefreshStatusDidChange: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.backgroundRefreshStatusDidChangeNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.protectedDataWillBecomeUnavailableNotification`
    public static var protectedDataWillBecomeUnavailable: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.protectedDataWillBecomeUnavailableNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.protectedDataDidBecomeAvailableNotification`
    public static var protectedDataDidBecomeAvailable: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.protectedDataDidBecomeAvailableNotification).map { _ in }
        
        return ControlEvent(events: source)
    }
    
    /// Reactive wrapper for `UIApplication.userDidTakeScreenshotNotification`
    public static var userDidTakeScreenshot: ControlEvent<Void> {
        let source = NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification).map { _ in }

        return ControlEvent(events: source)
    }
}
#endif
