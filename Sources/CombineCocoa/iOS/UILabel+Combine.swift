#if os(iOS) || os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UILabel {
    
    /// Bindable sink for `text` property.
    /// ```swift
    /// let subject = PassthroughSubject<String, Never>()
    /// subject.subscribe(label.cb.text)
    /// subject.send("Hello, World!")
    /// ```
    var text: Binder<String> {
        Binder(self.base) { label, text in
            label.text = text
        }
    }
}
#endif
