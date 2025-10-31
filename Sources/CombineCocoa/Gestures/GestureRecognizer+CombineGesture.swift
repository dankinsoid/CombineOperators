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
import struct CoreGraphics.CGPoint

public typealias LocationInView = (CombineGestureView) -> CGPoint

public extension Publisher where Output: CombineGestureRecognizer {
	/// Filters gesture events by recognizer state.
	///
	/// ```swift
	/// view.cb.gesture(panGesture)
	///     .when(.began, .changed)
	///     .sink { /* handle pan */ }
	/// ```
	func when(_ states: CombineGestureRecognizerState...) -> AnyPublisher<Output, Failure> {
		filter { gesture in
			states.contains(gesture.state)
		}
		.eraseToAnyPublisher()
	}

	/// Filters gesture events by recognizer state (internal array version).
	internal func when(_ states: [CombineGestureRecognizerState]) -> AnyPublisher<Output, Failure> {
		filter { gesture in
			states.contains(gesture.state)
		}
		.eraseToAnyPublisher()
	}

	/// Maps gesture events to location points in target view's coordinate space.
	func asLocation(in view: TargetView = .view) -> AnyPublisher<CombineGesturePoint, Failure> {
		map { gesture in
			gesture.location(in: view.targetView(for: gesture))
		}
		.eraseToAnyPublisher()
	}

	/// Maps gesture events to location converter closures for dynamic coordinate conversion.
	func asLocationInView() -> AnyPublisher<LocationInView, Failure> {
		map { gesture in
			let targetView = gesture.view!
			let location = gesture.location(in: targetView)
			return { view in
				targetView.convert(location, to: view)
			}
		}
		.eraseToAnyPublisher()
	}
}
