import Combine
import Foundation

extension Reactive where Base: AnyObject {

    /// A set of AnyCancellable instances stored per object.
    /// Used to retain subscriptions.
    public var cancellables: ReactiveCancellables {
        get {
            if let value = objc_getAssociatedObject(base, &ReactiveCancellablesKey) as? ReactiveCancellables {
                return value
            } else {
                let cancellables = ReactiveCancellables()
                objc_setAssociatedObject(base, &ReactiveCancellablesKey, cancellables, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return cancellables
            }
        }
        nonmutating set {
            objc_setAssociatedObject(base, &ReactiveCancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

public final class ReactiveCancellables: RangeReplaceableCollection {

    public typealias Index = Set<AnyCancellable>.Index
    public typealias Element = AnyCancellable
    public typealias SubSequence = Slice<ReactiveCancellables>

    public var startIndex: Index { storage.startIndex }
    public var endIndex: Index { storage.endIndex }
    public var count: Int { storage.count }
    private var storage: Set<AnyCancellable> = []

    public init() {}

    public init<S>(_ elements: S) where S : Sequence, Element == S.Element {
        storage = Set(elements)
    }

    public subscript(position: Index) -> AnyCancellable {
        storage[position]
    }

    public func index(after i: Index) -> Index {
        storage.index(after: i)
    }

    public func replaceSubrange<C>(_ subrange: Range<Index>, with newElements: C) where C : Collection, AnyCancellable == C.Element {
        storage.subtract(storage[subrange])
        storage.formUnion(newElements)
    }
}

private var ReactiveCancellablesKey: UInt8 = 0
