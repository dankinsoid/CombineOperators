//
//  UISearchBar+Combine.swift
//  CombineCocoa
//
//  Created by Krunoslav Zaher on 3/28/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

import Combine
import UIKit

@available(iOS 13.0, macOS 10.15, *)
extension Reactive where Base: UISearchBar {

    /// Reactive wrapper for `delegate`.
    ///
    /// For more information take a look at `DelegateProxyType` protocol documentation.
    public var delegate: DelegateProxy<UISearchBar, UISearchBarDelegate> {
        CombineSearchBarDelegateProxy.proxy(for: base)
    }

    /// Reactive wrapper for `text` property.
    public var text: ControlProperty<String?> {
        value
    }
    
    /// Reactive wrapper for `text` property.
    public var value: ControlProperty<String?> {
        let source = Deferred { [weak searchBar = self.base as UISearchBar] () -> AnyPublisher<String?, Error> in
            let text = searchBar?.text

					let textDidChange = searchBar?.cb.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBar(_:textDidChange:)))
						.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
					let didEndEditing = searchBar?.cb.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarTextDidEndEditing(_:)))
						.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
            
					return textDidChange.merge(with: didEndEditing)
                    .map { _ in searchBar?.text ?? "" }
                    .prepend(text)
										.eraseToAnyPublisher()
        }
        
        let bindingObserver = Binder(self.base) { (searchBar, text: String?) in
            searchBar.text = text
        }

        return ControlProperty(values: source, valueSink: bindingObserver)
    }
    
    /// Reactive wrapper for `selectedScopeButtonIndex` property.
    public var selectedScopeButtonIndex: ControlProperty<Int> {
        let source = Deferred { [weak source = self.base as UISearchBar] () -> AnyPublisher<Int, Error> in
            let index = source?.selectedScopeButtonIndex ?? 0
            
					return source?.cb.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBar(_:selectedScopeButtonIndexDidChange:)))
                .tryMap { a in
										try castOrThrow(Int.self, a[1])
                }
                .prepend(index)
							.eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
        }
        
        let bindingObserver = Binder(self.base) { (searchBar, index: Int) in
            searchBar.selectedScopeButtonIndex = index
        }
        
        return ControlProperty(values: source, valueSink: bindingObserver)
    }
    
#if os(iOS)
    /// Reactive wrapper for delegate method `searchBarCancelButtonClicked`.
    public var cancelButtonClicked: ControlEvent<Void> {
        let source = self.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarCancelButtonClicked(_:)))
            .map { _ in
                return ()
            }
        return ControlEvent(events: source)
    }

	/// Reactive wrapper for delegate method `searchBarBookmarkButtonClicked`.
	public var bookmarkButtonClicked: ControlEvent<Void> {
		let source = self.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarBookmarkButtonClicked(_:)))
			.map { _ in
				return ()
			}
		return ControlEvent(events: source)
	}

	/// Reactive wrapper for delegate method `searchBarResultsListButtonClicked`.
	public var resultsListButtonClicked: ControlEvent<Void> {
		let source = self.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarResultsListButtonClicked(_:)))
			.map { _ in
				return ()
		}
		return ControlEvent(events: source)
	}
#endif
	
    /// Reactive wrapper for delegate method `searchBarSearchButtonClicked`.
    public var searchButtonClicked: ControlEvent<Void> {
        let source = self.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarSearchButtonClicked(_:)))
            .map { _ in
                return ()
        }
        return ControlEvent(events: source)
    }
	
	/// Reactive wrapper for delegate method `searchBarTextDidBeginEditing`.
	public var textDidBeginEditing: ControlEvent<Void> {
		let source = self.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarTextDidBeginEditing(_:)))
			.map { _ in
				return ()
		}
		return ControlEvent(events: source)
	}
	
	/// Reactive wrapper for delegate method `searchBarTextDidEndEditing`.
	public var textDidEndEditing: ControlEvent<Void> {
		let source = self.delegate.methodInvoked(#selector(UISearchBarDelegate.searchBarTextDidEndEditing(_:)))
			.map { _ in
				return ()
		}
		return ControlEvent(events: source)
	}
  
    /// Installs delegate as forwarding delegate on `delegate`.
    /// Delegate won't be retained.
    ///
    /// It enables using normal delegate mechanism with reactive delegate mechanism.
    ///
    /// - parameter delegate: Delegate object.
    /// - returns: Cancellable object that can be used to unbind the delegate.
    public func setDelegate(_ delegate: UISearchBarDelegate)
        -> Cancellable {
        CombineSearchBarDelegateProxy.installForwardDelegate(delegate, retainDelegate: false, onProxyForObject: self.base)
    }
	
	public var changes: ControlEvent<String> {
		let first = text.map { $0 ?? "" }
		let second = textDidEndEditing.map {[weak base] in base?.text ?? "" }
		let third = cancelButtonClicked.map { "" }
		return ControlEvent(events: first.merge(with: second, third))
	}

}

#endif
