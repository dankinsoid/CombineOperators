#if canImport(UIKit)
import UIKit
import Combine

extension Reactive where Base: UIStackView {

	/// Binds array to stack view's arranged subviews with custom update logic.
	///
	/// Adds/removes views as needed to match array count, then updates each view.
	///
	/// ```swift
	/// array.subscribe(stackView.cb.update(
	///     create: { UILabel() },
	///     update: { text, label, index in label.text = text }
	/// ))
	/// ```
	public func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (T, V, Int) -> Void) -> Binder<[T]> {
		Binder(base) {
			$0.update(items: $1, create: create, update: update)
		}
	}

	/// Binds array to stack view using subscriber-based update pattern.
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
