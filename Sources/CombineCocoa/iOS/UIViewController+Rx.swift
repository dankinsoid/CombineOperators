//
//  File.swift
//
//
//  Created by Данил Войдилов on 17.02.2021.
//

import Combine
import UIKit

@available(iOS 13.0, macOS 10.15, *)
public extension Reactive where Base: UIViewController {
	
	var viewDidLoad: ControlEvent<Void> {
		let source = self.methodInvoked(#selector(Base.viewDidLoad)).map { _ in }
		return ControlEvent(events: source)
	}
	
	var viewWillAppear: ControlEvent<Bool> {
		let source = self.methodInvoked(#selector(Base.viewWillAppear)).map { $0.first as? Bool ?? false }
		return ControlEvent(events: source)
	}
	var viewDidAppear: ControlEvent<Bool> {
		let source = self.methodInvoked(#selector(Base.viewDidAppear)).map { $0.first as? Bool ?? false }
		return ControlEvent(events: source)
	}
	
	var viewWillDisappear: ControlEvent<Bool> {
		let source = self.methodInvoked(#selector(Base.viewWillDisappear)).map { $0.first as? Bool ?? false }
		return ControlEvent(events: source)
	}
	var viewDidDisappear: ControlEvent<Bool> {
		let source = self.methodInvoked(#selector(Base.viewDidDisappear)).map { $0.first as? Bool ?? false }
		return ControlEvent(events: source)
	}
	
	var viewWillLayoutSubviews: ControlEvent<Void> {
		let source = self.methodInvoked(#selector(Base.viewWillLayoutSubviews)).map { _ in }
		return ControlEvent(events: source)
	}
	var viewDidLayoutSubviews: ControlEvent<Void> {
		let source = self.methodInvoked(#selector(Base.viewDidLayoutSubviews)).map { _ in }
		return ControlEvent(events: source)
	}
	
	var willMoveToParentViewController: ControlEvent<UIViewController?> {
		let source = self.methodInvoked(#selector(Base.willMove)).map { $0.first as? UIViewController }
		return ControlEvent(events: source)
	}
	var didMoveToParentViewController: ControlEvent<UIViewController?> {
		let source = self.methodInvoked(#selector(Base.didMove)).map { $0.first as? UIViewController }
		return ControlEvent(events: source)
	}
	
	var didReceiveMemoryWarning: ControlEvent<Void> {
		let source = self.methodInvoked(#selector(Base.didReceiveMemoryWarning)).map { _ in }
		return ControlEvent(events: source)
	}
	
	/// Rx observable, triggered when the ViewController appearance state changes (true if the View is being displayed, false otherwise)
	var isVisible: AnyPublisher<Bool, Never> {
		let viewDidAppearObservable = viewDidAppear.map { _ in true }
		let viewWillDisappearObservable = viewDidDisappear.map { _ in false }
		return viewDidAppearObservable
			.merge(with: viewWillDisappearObservable)
			.prepend(base.viewIfLoaded?.window != nil)
			.eraseToAnyPublisher()
	}
	
	/// Rx observable, triggered when the ViewController is being dismissed
	var isDismissing: ControlEvent<Bool> {
		let source = self.sentMessage(#selector(Base.dismiss)).map { $0.first as? Bool ?? false }
		return ControlEvent(events: source)
	}
	
}
