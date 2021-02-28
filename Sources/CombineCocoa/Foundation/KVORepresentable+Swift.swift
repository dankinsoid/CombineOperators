//
//  KVORepresentable+Swift.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 11/14/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

@available(iOS 13.0, macOS 10.15, *)
extension Int : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.int32Value)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Int32 : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.int32Value)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Int64 : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.int64Value)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension UInt : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.uintValue)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension UInt32 : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.uint32Value)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension UInt64 : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.uint64Value)
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension Bool : KVORepresentable {
    public typealias KVOType = NSNumber

    /// Constructs `Self` using KVO value.
    public init?(KVOValue: KVOType) {
        self.init(KVOValue.boolValue)
    }
}


@available(iOS 13.0, macOS 10.15, *)
extension RawRepresentable where RawValue: KVORepresentable {
    /// Constructs `Self` using optional KVO value.
    init?(KVOValue: RawValue.KVOType?) {
        guard let KVOValue = KVOValue else {
            return nil
        }

        guard let rawValue = RawValue(KVOValue: KVOValue) else {
            return nil
        }

        self.init(rawValue: rawValue)
    }
}
