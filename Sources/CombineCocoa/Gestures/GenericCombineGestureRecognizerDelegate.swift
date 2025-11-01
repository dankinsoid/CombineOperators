// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif
import Combine

/// Policy for controlling gesture recognizer delegate decisions.
///
/// ```swift
/// let policy = GestureRecognizerDelegatePolicy<UITapGestureRecognizer>.custom { gesture in
///     gesture.numberOfTouches == 2
/// }
/// ```
public struct GestureRecognizerDelegatePolicy<PolicyInput> {
	public typealias PolicyBody = (PolicyInput) -> Bool

	private let policy: PolicyBody

	private init(policy: @escaping PolicyBody) {
		self.policy = policy
	}

	/// Creates custom policy with closure.
	public static func custom(_ policy: @escaping PolicyBody)
		-> GestureRecognizerDelegatePolicy<PolicyInput>
	{
		.init(policy: policy)
	}

	/// Policy that always returns true.
	public static var always: GestureRecognizerDelegatePolicy<PolicyInput> {
		.init { _ in true }
	}

	/// Policy that always returns false.
	public static var never: GestureRecognizerDelegatePolicy<PolicyInput> {
		.init { _ in false }
	}

	public func isPolicyPassing(with args: PolicyInput) -> Bool {
		policy(args)
	}
}

public func || <PolicyInput>(lhs: GestureRecognizerDelegatePolicy<PolicyInput>, rhs: GestureRecognizerDelegatePolicy<PolicyInput>) -> GestureRecognizerDelegatePolicy<PolicyInput> {
	.custom { input in
		lhs.isPolicyPassing(with: input) || rhs.isPolicyPassing(with: input)
	}
}

public func && <PolicyInput>(lhs: GestureRecognizerDelegatePolicy<PolicyInput>, rhs: GestureRecognizerDelegatePolicy<PolicyInput>) -> GestureRecognizerDelegatePolicy<PolicyInput> {
	.custom { input in
		lhs.isPolicyPassing(with: input) && rhs.isPolicyPassing(with: input)
	}
}

/// Configurable gesture recognizer delegate with policy-based decision making.
///
/// Set policies to control gesture behavior without subclassing.
public final class GenericRxGestureRecognizerDelegate<Gesture: CombineGestureRecognizer>: NSObject, CombineGestureRecognizerDelegate {
	/// Controls `gestureRecognizerShouldBegin(_:)`.
	public var beginPolicy: GestureRecognizerDelegatePolicy<Gesture> = .always

	/// Controls `gestureRecognizer(_:shouldReceive:)` for touches.
	public var touchReceptionPolicy: GestureRecognizerDelegatePolicy<(Gesture, CombineGestureTouch)> = .always

	/// Controls `gestureRecognizer(_:shouldBeRequiredToFailBy:)`.
	public var selfFailureRequirementPolicy: GestureRecognizerDelegatePolicy<(Gesture, CombineGestureRecognizer)> = .never

	/// Controls `gestureRecognizer(_:shouldRequireFailureOf:)`.
	public var otherFailureRequirementPolicy: GestureRecognizerDelegatePolicy<(Gesture, CombineGestureRecognizer)> = .never

	/// Controls `gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)`.
	public var simultaneousRecognitionPolicy: GestureRecognizerDelegatePolicy<(Gesture, CombineGestureRecognizer)> = .always

	#if os(iOS)
	private var _pressReceptionPolicy: Any?

	/// Controls `gestureRecognizer(_:shouldReceive:)` for presses.
	public var pressReceptionPolicy: GestureRecognizerDelegatePolicy<(Gesture, UIPress)> {
		get {
			_pressReceptionPolicy as? GestureRecognizerDelegatePolicy<(Gesture, UIPress)> ?? .always
		}
		set {
			_pressReceptionPolicy = newValue
		}
	}
	#endif

	#if os(OSX)
	/// Controls `gestureRecognizer(_:shouldAttemptToRecognizeWith:)`.
	public var eventRecognitionAttemptPolicy: GestureRecognizerDelegatePolicy<(Gesture, NSEvent)> = .always
	#endif

	public func gestureRecognizerShouldBegin(
		_ gestureRecognizer: CombineGestureRecognizer
	) -> Bool {
		beginPolicy.isPolicyPassing(with: gestureRecognizer as! Gesture)
	}

	public func gestureRecognizer(
		_ gestureRecognizer: CombineGestureRecognizer,
		shouldReceive touch: CombineGestureTouch
	) -> Bool {
		touchReceptionPolicy.isPolicyPassing(
			with: (gestureRecognizer as! Gesture, touch)
		)
	}

	public func gestureRecognizer(
		_ gestureRecognizer: CombineGestureRecognizer,
		shouldRequireFailureOf otherGestureRecognizer: CombineGestureRecognizer
	) -> Bool {
		otherFailureRequirementPolicy.isPolicyPassing(
			with: (gestureRecognizer as! Gesture, otherGestureRecognizer)
		)
	}

	public func gestureRecognizer(
		_ gestureRecognizer: CombineGestureRecognizer,
		shouldBeRequiredToFailBy otherGestureRecognizer: CombineGestureRecognizer
	) -> Bool {
		selfFailureRequirementPolicy.isPolicyPassing(
			with: (gestureRecognizer as! Gesture, otherGestureRecognizer)
		)
	}

	public func gestureRecognizer(
		_ gestureRecognizer: CombineGestureRecognizer,
		shouldRecognizeSimultaneouslyWith otherGestureRecognizer: CombineGestureRecognizer
	) -> Bool {
		simultaneousRecognitionPolicy.isPolicyPassing(
			with: (gestureRecognizer as! Gesture, otherGestureRecognizer)
		)
	}

	#if os(iOS)

	public func gestureRecognizer(
		_ gestureRecognizer: CombineGestureRecognizer,
		shouldReceive press: UIPress
	) -> Bool {
		pressReceptionPolicy.isPolicyPassing(
			with: (gestureRecognizer as! Gesture, press)
		)
	}

	#endif

	#if os(OSX)

	public func gestureRecognizer(
		_ gestureRecognizer: CombineGestureRecognizer,
		shouldAttemptToRecognizeWith event: NSEvent
	) -> Bool {
		eventRecognitionAttemptPolicy.isPolicyPassing(
			with: (gestureRecognizer as! Gesture, event)
		)
	}

	#endif
}
