#if os(iOS) || os(tvOS)

import Combine
import UIKit

public extension Reactive where Base: UITextView {

    /// Bidirectional binding for text field's `text` property.
    ///
    /// ```swift
    /// textView.cb.text
    ///     .sink { print("Text: \($0 ?? "")") }
    ///
    /// publisher.subscribe(textView.cb.text) // Bind to text field
    /// ```
    var text: ControlProperty<String> {
        ControlProperty(
            values: Deferred { [weak base] () -> AnyPublisher<String, Never> in
                guard let base else {
                    return Empty().eraseToAnyPublisher()
                }
                return NotificationCenter.default
                    .publisher(for: UITextView.textDidChangeNotification, object: base)
                    .prefix(untilOutputFrom: Publishers.OnDeinit(base))
                    .map { ($0.object as? UITextView)?.text ?? "" }
                    .prepend(base.text ?? "")
                    .eraseToAnyPublisher()
            },
            valueSink: Binder(base) {
                if $0.text != $1 {
                    $0.text = $1
                }
            }
        )
    }

    /// Bidirectional binding for text field's `attributedText` property.
    var attributedText: ControlProperty<NSAttributedString> {
        ControlProperty(
            values: Deferred { [weak base] () -> AnyPublisher<NSAttributedString, Never> in
                guard let base else {
                    return Empty().eraseToAnyPublisher()
                }
                return NotificationCenter.default
                    .publisher(for: UITextView.textDidChangeNotification, object: base)
                    .prefix(untilOutputFrom: Publishers.OnDeinit(base))
                    .map { ($0.object as? UITextView)?.attributedText ?? NSAttributedString() }
                    .prepend(base.attributedText ?? NSAttributedString())
                    .eraseToAnyPublisher()
            },
            valueSink: Binder(base) {
                if $0.attributedText != $1 {
                    $0.attributedText = $1
                }
            }
        )
    }
}

#endif
