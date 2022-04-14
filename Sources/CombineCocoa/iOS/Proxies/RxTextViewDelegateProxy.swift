//
//  CombineTextViewDelegateProxy.swift
//  CombineCocoa
//
//  Created by Yuta ToKoRo on 7/19/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import UIKit
import Combine

/// For more information take a look at `DelegateProxyType`.
@available(iOS 13.0, macOS 10.15, *)
open class CombineTextViewDelegateProxy
//    : CombineScrollViewDelegateProxy
: DelegateProxy<UITextView, UITextViewDelegate>, DelegateProxyType, UITextViewDelegate {
	public static func registerKnownImplementations() {
		self.register { CombineTextViewDelegateProxy(textView: $0) }
	}
	
	
	/// Typed parent object.
	public weak private(set) var textView: UITextView?
	
	/// - parameter textview: Parent object for delegate proxy.
	public init(textView: UITextView) {
		self.textView = textView
		super.init(parentObject: textView, delegateProxy: CombineTextViewDelegateProxy.self)

//		super.init(scrollView: textView)
	}
	
	// MARK: delegate methods
	
//	var forwardToDelegate(): UITextViewDelegate? {
//		self.forwardToDelegate() as? UITextViewDelegate
//	}
	
	/// For more information take a look at `DelegateProxyType`.
	@objc open func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		/**
		 We've had some issues with observing text changes. This is here just in case we need the same hack in future and that
		 we wouldn't need to change the public interface.
		 */
		let forwardToDelegate = self.forwardToDelegate() as? UITextViewDelegate
		return forwardToDelegate?.textView?(textView,
																				shouldChangeTextIn: range,
																				replacementText: text) ?? true
	}
	
	@objc open func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		forwardToDelegate()?.textViewShouldBeginEditing?(textView) ?? true
		
	}
	
	@objc open func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
		forwardToDelegate()?.textViewShouldEndEditing?(textView) ?? true
		
	}
	
	
	@objc open func textViewDidBeginEditing(_ textView: UITextView) {
		forwardToDelegate()?.textViewDidBeginEditing?(textView)
		
	}
	
	@objc open func textViewDidEndEditing(_ textView: UITextView) {
		forwardToDelegate()?.textViewDidEndEditing?(textView)
		
	}
	
	
	
	@objc open func textViewDidChange(_ textView: UITextView) {
		forwardToDelegate()?.textViewDidChange?(textView)
	}
	
	
	@objc open func textViewDidChangeSelection(_ textView: UITextView) {
		(forwardToDelegate()?.textViewDidChangeSelection)?(textView)
		
	}
	
	
	@objc open func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		forwardToDelegate()?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
	}
	
	@objc open func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
		forwardToDelegate()?.textView?(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction) ?? true
	}
	
	public static func currentDelegate(for object: UITextView) -> UITextViewDelegate? {
		object.delegate
	}
	
	public static func setCurrentDelegate(_ delegate: UITextViewDelegate?, to object: UITextView) {
		object.delegate = delegate
	}
	
	private var _contentOffsetBehaviorSubject: CurrentValueSubject<CGPoint, Never>?
	private var _contentOffsetPublishSubject: PassthroughSubject<(), Error>?

	/// Optimized version used for observing content offset changes.
	internal var contentOffsetBehaviorSubject: CurrentValueSubject<CGPoint, Never> {
			if let subject = _contentOffsetBehaviorSubject {
					return subject
			}

			let subject = CurrentValueSubject<CGPoint, Never>(self.textView?.contentOffset ?? CGPoint.zero)
			_contentOffsetBehaviorSubject = subject

			return subject
	}

	/// Optimized version used for observing content offset changes.
	internal var contentOffsetPublishSubject: PassthroughSubject<(), Error> {
			if let subject = _contentOffsetPublishSubject {
					return subject
			}

			let subject = PassthroughSubject<(), Error>()
			_contentOffsetPublishSubject = subject

			return subject
	}
	
	// MARK: delegate methods

	/// For more information take a look at `DelegateProxyType`.
	public func scrollViewDidScroll(_ scrollView: UIScrollView) {
			if let subject = _contentOffsetBehaviorSubject {
					subject.send(scrollView.contentOffset)
			}
			if let subject = _contentOffsetPublishSubject {
					subject.send()
			}
			self._forwardToDelegate?.scrollViewDidScroll?(scrollView)
	}
	
	deinit {
			if let subject = _contentOffsetBehaviorSubject {
				subject.send(completion: .finished)
			}

			if let subject = _contentOffsetPublishSubject {
					subject.send(completion: .finished)
			}
	}
}

#endif

