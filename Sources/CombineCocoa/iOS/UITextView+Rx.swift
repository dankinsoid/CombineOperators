//
//  UITextView+Combine.swift
//  CombineCocoa
//
//  Created by Yuta ToKoRo on 7/19/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import UIKit

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UITextView {
    /// Reactive wrapper for `text` property
    public var text: ControlProperty<String?> {
        value
    }
    
    /// Reactive wrapper for `text` property.
    public var value: ControlProperty<String?> {
        let source = Deferred { [weak base] () -> AnyPublisher<String?, Error> in
            let text = base?.text
            
            let textChanged = base?.textStorage
                // This project uses text storage notifications because
                // that's the only way to catch autocorrect changes
                // in all cases. Other suggestions are welcome.
                .cb.didProcessEditingRangeChangeInLength
                // This observe on is here because text storage
                // will emit event while process is not completely done,
                // so rebinding a value will cause an exception to be thrown.
								.receive(on: DispatchQueue.main)
                .map { _ in
                    return base?.textStorage.string
                }
            
					return textChanged?.prepend(text).eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
        }

        let bindingObserver = Binder(self.base) { (textView, text: String?) in
            // This check is important because setting text value always clears control state
            // including marked text selection which is imporant for proper input 
            // when IME input method is used.
            if textView.text != text {
                textView.text = text
            }
        }
        
        return ControlProperty(values: source, valueSink: bindingObserver)
    }
    
    
    /// Reactive wrapper for `attributedText` property.
    public var attributedText: ControlProperty<NSAttributedString?> {
        let source = Deferred { [weak base] () -> AnyPublisher<NSAttributedString?, Error> in
            let attributedText = base?.attributedText
            
            let textChanged = base?.textStorage
                // This project uses text storage notifications because
                // that's the only way to catch autocorrect changes
                // in all cases. Other suggestions are welcome.
                .cb.didProcessEditingRangeChangeInLength
                // This observe on is here because attributedText storage
                // will emit event while process is not completely done,
                // so rebinding a value will cause an exception to be thrown.
								.receive(on: DispatchQueue.main)
                .map { _ in
                    return base?.attributedText
                }
            
            return textChanged?.prepend(attributedText).eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
        }
        
        let bindingObserver = Binder(self.base) { (textView, attributedText: NSAttributedString?) in
            // This check is important because setting text value always clears control state
            // including marked text selection which is imporant for proper input
            // when IME input method is used.
            if textView.attributedText != attributedText {
                textView.attributedText = attributedText
            }
        }
        
        return ControlProperty(values: source, valueSink: bindingObserver)
    }

    /// Reactive wrapper for `delegate` message.
    public var didBeginEditing: ControlEvent<()> {
       return ControlEvent<()>(events: self.delegate.methodInvoked(#selector(UITextViewDelegate.textViewDidBeginEditing(_:)))
            .map { _ in
                return ()
            })
    }

    /// Reactive wrapper for `delegate` message.
    public var didEndEditing: ControlEvent<()> {
        return ControlEvent<()>(events: self.delegate.methodInvoked(#selector(UITextViewDelegate.textViewDidEndEditing(_:)))
            .map { _ in
                return ()
            })
    }

    /// Reactive wrapper for `delegate` message.
    public var didChange: ControlEvent<()> {
        return ControlEvent<()>(events: self.delegate.methodInvoked(#selector(UITextViewDelegate.textViewDidChange(_:)))
            .map { _ in
                return ()
            })
    }

    /// Reactive wrapper for `delegate` message.
    public var didChangeSelection: ControlEvent<()> {
        return ControlEvent<()>(events: self.delegate.methodInvoked(#selector(UITextViewDelegate.textViewDidChangeSelection(_:)))
            .map { _ in
                return ()
            })
    }

}

#endif
