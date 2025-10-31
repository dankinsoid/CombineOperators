// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Combine
import CombineOperators
import Dispatch

public extension Reactive where Base: CombineGestureView {

	/// Observes multiple gesture recognizers with state filtering.
	///
	/// Auto-attaches gestures to view. Emits gesture recognizer on specified states.
	///
	/// ```swift
	/// view.cb.anyGesture(
	///     (tapGesture, when: .recognized),
	///     (panGesture, when: .changed)
	/// ).sink { gesture in /* handle */ }
	/// ```
	func anyGesture(_ factories: (AnyFactory, when: CombineGestureRecognizerState)...) -> ControlEvent<CombineGestureRecognizer> {
		let publishers = factories.map { gesture, state in
			self.gesture(gesture).when(state)
		}
		return ControlEvent(events: Publishers.MergeMany(publishers))
	}

	/// Observes multiple gesture recognizers (all states).
	///
	/// Auto-attaches gestures to view. Emits gesture recognizer on any state change.
	func anyGesture(_ factories: AnyFactory...) -> ControlEvent<CombineGestureRecognizer> {
		let publishers = factories.map { factory in
			self.gesture(factory)
		}
		return ControlEvent(events: Publishers.MergeMany(publishers))
	}

	/// Observes single gesture recognizer created from factory.
	///
	/// Auto-attaches gesture to view. Emits gesture recognizer on state changes.
	func gesture<G>(_ factory: Factory<G>) -> ControlEvent<G> {
		gesture(factory.gesture)
	}

	/// Observes single gesture recognizer instance.
	///
	/// Auto-attaches gesture to view. Emits gesture recognizer on state changes.
	/// Removes gesture on cancellation.
	///
	/// ```swift
	/// let tap = UITapGestureRecognizer()
	/// view.cb.gesture(tap)
	///     .sink { recognizer in print("Tapped") }
	/// ```
	func gesture<G: CombineGestureRecognizer>(_ gesture: G) -> ControlEvent<G> {
		let source = Deferred { [weak control = self.base] () -> AnyPublisher<G, Never> in
			DispatchQueue.ensureRunningOnMainThread()

			guard let control else { return Empty().eraseToAnyPublisher() }

			let genericGesture = gesture as CombineGestureRecognizer

			#if os(iOS)
			control.isUserInteractionEnabled = true
			#endif

			control.addGestureRecognizer(gesture)

			return genericGesture.cb.event
				.compactMap { $0 as? G }
				.prepend(gesture)
				.handleEvents(receiveCancel: { [weak control, weak gesture] () in
					guard let gesture else { return }
					DispatchQueue.main.async {
						control?.removeGestureRecognizer(gesture)
					}
				})
//				.prefix(untilOutputFrom: control.cb.deallocated)
				.eraseToAnyPublisher()
		}
		return ControlEvent(events: source)
	}
}
