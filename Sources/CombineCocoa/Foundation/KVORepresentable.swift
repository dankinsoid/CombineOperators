//
//  KVORepresentable.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 11/14/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Type that is KVO representable (KVO mechanism can be used to observe it).
@available(iOS 13.0, macOS 10.15, *)
public protocol KVORepresentable {
    /// Associated KVO type.
    associatedtype KVOType

    /// Constructs `Self` using KVO value.
    init?(KVOValue: KVOType)
}

@available(iOS 13.0, macOS 10.15, *)
extension KVORepresentable {
    /// Initializes `KVORepresentable` with optional value.
    init?(KVOValue: KVOType?) {
        guard let KVOValue = KVOValue else {
            return nil
        }

        self.init(KVOValue: KVOValue)
    }
}

