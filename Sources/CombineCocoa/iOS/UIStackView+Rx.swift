#if canImport(UIKit)
import UIKit
import Combine

extension Reactive where Base: UIStackView {
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (T, V, Int) -> Void) -> Binder<[T]> {
		Binder(base) {
			$0.update(items: $1, create: create, update: update)
		}
	}
	
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (V) -> AnySubscriber<T, Error>) -> Binder<[T]> {
		self.update(create: create) { value, view, _ in
			_ = update(view).receive(value)
		}
	}
	
}

extension UIStackView {
	
	func update<T, V: UIView>(items: [T], create: () -> V, update: (T, V, Int) -> ()) {
		let dif = arrangedSubviews.count - items.count
		arrangedSubviews.suffix(max(0, dif)).reversed().forEach {
			removeArrangedSubview($0)
			$0.removeFromSuperview()
		}
		if dif < 0 {
			for _ in 0..<abs(dif) { addArrangedSubview(create()) }
		}
		zip(items, arrangedSubviews.compactMap { $0 as? V }).enumerated().forEach {
			update($0.element.0, $0.element.1, $0.offset)
		}
	}
}
#endif
