//
//  File.swift
//  
//
//  Created by Данил Войдилов on 28.02.2021.
//

#if os(iOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
public protocol CombineKeyboardType {
	var frame: AnyPublisher<CGRect, Never> { get }
	var visibleHeight: AnyPublisher<CGFloat, Never> { get }
	var willShowVisibleHeight: AnyPublisher<CGFloat, Never> { get }
	var isHidden: AnyPublisher<Bool, Never> { get }
}

/// RxKeyboard provides a reactive way of observing keyboard frame changes.
@available(iOS 13.0, macOS 10.15, *)
public class CombineKeyboard: NSObject, CombineKeyboardType {
	
	// MARK: Public
	/// Get a singleton instance.
	public static let instance = CombineKeyboard()
	
	/// An observable keyboard frame.
	public let frame: AnyPublisher<CGRect, Never>
	
	/// An observable visible height of keyboard. Emits keyboard height if the keyboard is visible
	/// or `0` if the keyboard is not visible.
	public let visibleHeight: AnyPublisher<CGFloat, Never>
	
	/// Same with `visibleHeight` but only emits values when keyboard is about to show. This is
	/// useful when adjusting scroll view content offset.
	public let willShowVisibleHeight: AnyPublisher<CGFloat, Never>
	
	/// An observable visibility of keyboard. Emits keyboard visibility
	/// when changed keyboard show and hide.
	public let isHidden: AnyPublisher<Bool, Never>
	
	// MARK: Private
	private var disposeBag = Set<AnyCancellable>()
	private let panRecognizer = UIPanGestureRecognizer()
	
	// MARK: Initializing
	override init() {
		
		let keyboardWillChangeFrame = UIResponder.keyboardWillChangeFrameNotification
		let keyboardWillHide = UIResponder.keyboardWillHideNotification
		let keyboardFrameEndKey = UIResponder.keyboardFrameEndUserInfoKey
		
		let defaultFrame = CGRect(
			x: 0,
			y: UIScreen.main.bounds.height,
			width: UIScreen.main.bounds.width,
			height: 0
		)
		let frameVariable = CurrentValueSubject<CGRect, Never>(defaultFrame)
		self.frame = frameVariable.removeDuplicates().asDriver().eraseToAnyPublisher()
		self.visibleHeight = self.frame.map { UIScreen.main.bounds.height - $0.origin.y }.eraseToAnyPublisher()
		self.willShowVisibleHeight = self.visibleHeight
			.scan((visibleHeight: 0, isShowing: false)) { lastState, newVisibleHeight in
				return (visibleHeight: newVisibleHeight, isShowing: lastState.visibleHeight == 0 && newVisibleHeight > 0)
			}
			.filter { state in state.isShowing }
			.map { state in state.visibleHeight }
			.eraseToAnyPublisher()
		self.isHidden = self.visibleHeight.map({ $0 == 0.0 }).removeDuplicates().eraseToAnyPublisher()
		super.init()
		
		// keyboard will change frame
		let willChangeFrame = NotificationCenter.default.publisher(for: keyboardWillChangeFrame)
			.map { notification -> CGRect in
				let rectValue = notification.userInfo?[keyboardFrameEndKey] as? NSValue
				return rectValue?.cgRectValue ?? defaultFrame
			}
			.map { frame -> CGRect in
				if frame.origin.y < 0 { // if went to wrong frame
					var newFrame = frame
					newFrame.origin.y = UIScreen.main.bounds.height - newFrame.height
					return newFrame
				}
				return frame
			}
		
		// keyboard will hide
		let willHide = NotificationCenter.default.publisher(for: keyboardWillHide)
			.map { notification -> CGRect in
				let rectValue = notification.userInfo?[keyboardFrameEndKey] as? NSValue
				return rectValue?.cgRectValue ?? defaultFrame
			}
			.map { frame -> CGRect in
				if frame.origin.y < 0 { // if went to wrong frame
					var newFrame = frame
					newFrame.origin.y = UIScreen.main.bounds.height
					return newFrame
				}
				return frame
			}
		
		// pan gesture
		let didPan = self.panRecognizer.cb.event
			.withLatestFrom(frameVariable) { ($0, $1) }
			.flatMap { (gestureRecognizer, frame) -> AnyPublisher<CGRect, Never> in
				guard case .changed = gestureRecognizer.state,
							let window = UIApplication.shared.windows.first,
							frame.origin.y < UIScreen.main.bounds.height
				else { return Empty().eraseToAnyPublisher() }
				let origin = gestureRecognizer.location(in: window)
				var newFrame = frame
				newFrame.origin.y = max(origin.y, UIScreen.main.bounds.height - frame.height)
				return Just(newFrame).eraseToAnyPublisher()
			}
		
		// merge into single sequence
		didPan.merge(with: willChangeFrame, willHide)
			.subscribe(frameVariable)
			.store(in: &disposeBag)
		
		// gesture recognizer
		self.panRecognizer.delegate = self
		
		if let window = UIApplication.shared.windows.first {
			window.addGestureRecognizer(panRecognizer)
		} else {
			UIApplication.cb.didFinishLaunching // when RxKeyboard is initialized before UIApplication.window is created
				.sink(receiveValue: { _ in
					UIApplication.shared.windows.first?.addGestureRecognizer(self.panRecognizer)
				})
				.store(in: &disposeBag)
		}
	}
	
}


// MARK: - UIGestureRecognizerDelegate
@available(iOS 13.0, macOS 10.15, *)
extension CombineKeyboard: UIGestureRecognizerDelegate {
	
	public func gestureRecognizer(
		_ gestureRecognizer: UIGestureRecognizer,
		shouldReceive touch: UITouch
	) -> Bool {
		let point = touch.location(in: gestureRecognizer.view)
		var view = gestureRecognizer.view?.hitTest(point, with: nil)
		while let candidate = view {
			if let scrollView = candidate as? UIScrollView,
				 case .interactive = scrollView.keyboardDismissMode {
				return true
			}
			view = candidate.superview
		}
		return false
	}
	
	public func gestureRecognizer(
		_ gestureRecognizer: UIGestureRecognizer,
		shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
	) -> Bool {
		gestureRecognizer === self.panRecognizer
	}
	
}
#endif
