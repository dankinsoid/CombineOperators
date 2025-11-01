// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#if canImport(UIKit)

import Combine
import UIKit

public typealias TapConfiguration = Configuration<UITapGestureRecognizer>
public typealias TapControlEvent = ControlEvent<UITapGestureRecognizer>
public typealias TapPublisher = AnyPublisher<UITapGestureRecognizer, Never>

public extension Factory where Gesture == CombineGestureRecognizer {
	/// Creates tap gesture factory with optional configuration.
	static func tap(configuration: TapConfiguration? = nil) -> AnyFactory {
		make(configuration: configuration).abstracted()
	}
}

public extension Reactive where Base: CombineGestureView {
	/// Observes tap gesture events.
	///
	/// ```swift
	/// view.cb.tapGesture { tap, _ in tap.numberOfTapsRequired = 2 }
	///     .sink { print("Double tapped") }
	/// ```
	func tapGesture(configuration: TapConfiguration? = nil) -> TapControlEvent {
		gesture(make(configuration: configuration))
	}
}

#endif
