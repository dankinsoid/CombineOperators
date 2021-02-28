//
//  KVORepresentable+CoreGraphics.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 11/14/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if !os(Linux)

import Combine
import CoreGraphics

import Foundation

#if arch(x86_64) || arch(arm64)
	let CGRectType = "{CGRect={CGPoint=dd}{CGSize=dd}}"
    let CGSizeType = "{CGSize=dd}"
    let CGPointType = "{CGPoint=dd}"
#elseif arch(i386) || arch(arm) || os(watchOS)
    let CGRectType = "{CGRect={CGPoint=ff}{CGSize=ff}}"
    let CGSizeType = "{CGSize=ff}"
    let CGPointType = "{CGPoint=ff}"
#endif

@available(iOS 13.0, macOS 10.15, *)
extension CGRect : KVORepresentable {
    public typealias KVOType = NSValue

    /// Constructs self from `NSValue`.
    public init?(KVOValue: KVOType) {
        if strcmp(KVOValue.objCType, CGRectType) != 0 {
            return nil
        }
        var typedValue = CGRect(x: 0, y: 0, width: 0, height: 0)
        KVOValue.getValue(&typedValue)
        self = typedValue
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension CGPoint : KVORepresentable {
    public typealias KVOType = NSValue

    /// Constructs self from `NSValue`.
    public init?(KVOValue: KVOType) {
        if strcmp(KVOValue.objCType, CGPointType) != 0 {
            return nil
        }
        var typedValue = CGPoint(x: 0, y: 0)
        KVOValue.getValue(&typedValue)
        self = typedValue
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension CGSize : KVORepresentable {
    public typealias KVOType = NSValue

    /// Constructs self from `NSValue`.
    public init?(KVOValue: KVOType) {
        if strcmp(KVOValue.objCType, CGSizeType) != 0 {
            return nil
        }
        var typedValue = CGSize(width: 0, height: 0)
        KVOValue.getValue(&typedValue)
        self = typedValue
    }
}

#endif
