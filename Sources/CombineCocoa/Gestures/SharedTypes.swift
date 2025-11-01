// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation

#if os(iOS)
import UIKit

public typealias CombineGestureTouch = UITouch
public typealias CombineGestureRecognizer = UIGestureRecognizer
public typealias CombineGestureRecognizerState = UIGestureRecognizer.State
public typealias CombineGestureRecognizerDelegate = UIGestureRecognizerDelegate
public typealias CombineGestureView = UIView
public typealias CombineGesturePoint = CGPoint
#elseif os(OSX)
import AppKit

public typealias CombineGestureTouch = NSTouch
public typealias CombineGestureRecognizer = NSGestureRecognizer
public typealias CombineGestureRecognizerState = NSGestureRecognizer.State
public typealias CombineGestureRecognizerDelegate = NSGestureRecognizerDelegate
public typealias CombineGestureView = NSView
public typealias CombineGesturePoint = NSPoint
#endif

/// Target coordinate space for gesture location calculations.
public enum TargetView {
	/// Gesture recognizer's own view.
	case view

	/// Gesture recognizer's superview.
	case superview

	/// Gesture recognizer's window.
	case window

	/// Specific custom view.
	case this(CombineGestureView)

	public func targetView(for gestureRecognizer: CombineGestureRecognizer) -> CombineGestureView? {
		switch self {
		case .view:
			return gestureRecognizer.view
		case .superview:
			return gestureRecognizer.view?.superview
		case .window:
			#if os(iOS)
			return gestureRecognizer.view?.window
			#elseif os(OSX)
			return gestureRecognizer.view?.window?.contentView
			#endif
		case let .this(view):
			return view
		}
	}
}
