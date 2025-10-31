#if canImport(UIKit)
import Combine
import UIKit

public extension Reactive where Base: UIStackView {

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
	func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (T, V, Int) -> Void) -> Binder<[T]> {
		Binder(base) {
			$0.update(items: $1, create: create, update: update)
		}
	}

	/// Binds array to stack view using subscriber-based update pattern.
	func update<T, V: UIView>(create: @escaping () -> V, update: @escaping (V) -> AnySubscriber<T, Error>) -> Binder<[T]> {
		self.update(create: create) { value, view, _ in
			_ = update(view).receive(value)
		}
	}
}

extension UIStackView {

	func update<T, V: UIView>(items: [T], create: () -> V, update: (T, V, Int) -> Void) {
		let dif = arrangedSubviews.count - items.count
		for item in arrangedSubviews.suffix(max(0, dif)).reversed() {
			removeArrangedSubview(item)
			item.removeFromSuperview()
		}
		if dif < 0 {
			for _ in 0 ..< abs(dif) {
				addArrangedSubview(create())
			}
		}
		for item in zip(items, arrangedSubviews.compactMap { $0 as? V }).enumerated() {
			update(item.element.0, item.element.1, item.offset)
		}
	}
}
#endif
