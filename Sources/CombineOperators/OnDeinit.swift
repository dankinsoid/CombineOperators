import Foundation
import Combine

public extension Publishers {

	struct OnDeinit: Publisher {

		public typealias Output = Void
		public typealias Failure = Never
		weak var object: AnyObject?

		public init(_ object: AnyObject?) {
			self.object = object
		}

		public func receive<S>(subscriber: S) where S: Subscriber, Never == S.Failure, Void == S.Input {
			let subscription = DeinitSubscription(
				subscriber: subscriber,
				object: object
			)
			subscriber.receive(subscription: subscription)
		}

		private final class DeinitSubscription<S: Subscriber>: Subscription where S.Input == Void, S.Failure == Never {

			private var subscriber: S?
			weak var object: AnyObject?
			private let lock = Lock()
            private var id: UUID?
			private var didSubscribe = false

			init(subscriber: S, object: AnyObject?) {
				self.subscriber = subscriber
				self.object = object
			}

			func request(_ demand: Subscribers.Demand) {
				guard demand > 0 else { return }
				let (object, didSubscribe) = lock.withLock {
					defer { self.didSubscribe = true }
					return (self.object, self.didSubscribe)
				}
				guard !didSubscribe else { return }

				guard let object else {
					finish()
					return
				}
				let deinitWrapper = (objc_getAssociatedObject(object, &deiniterKey) as? DeinitWrapper) ?? DeinitWrapper()
                lock.withLock {
                    id = deinitWrapper.add { [weak self] in
                        self?.finish()
                    }
                }
				objc_setAssociatedObject(object, &deiniterKey, deinitWrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			}

			func cancel() {
				let object = lock.withLock {
					subscriber = nil
					return self.object
				}
				if let object, let id, let wrapper = objc_getAssociatedObject(object, &deiniterKey) as? DeinitWrapper {
                    wrapper.remove(id: id)
				}
			}

			private func finish() {
				let subscriber = lock.withLock {
					defer { self.subscriber = nil }
					return self.subscriber
				}
				guard let subscriber else { return }
				_ = subscriber.receive(())
				subscriber.receive(completion: .finished)
			}
		}
	}
}

private final class DeinitWrapper {

    private let lock = Lock()
    private var closures: [UUID: () -> Void] = [:]

	init() {}

    func add(_ closure: @escaping () -> Void) -> UUID {
        let id = UUID()
        lock.withLock {
            closures[id] = closure
        }
        return id
    }
    
    func remove(id: UUID) {
        lock.withLock {
            closures.removeValue(forKey: id)
        }
    }
    
	deinit {
        closures.values.forEach { $0() }
	}
}

private var deiniterKey: UInt8 = 0
