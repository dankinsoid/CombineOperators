//
//  File.swift
//  
//
//  Created by Данил Войдилов on 26.02.2021.
//

import Foundation
import Combine

@available(iOS 13.0, macOS 10.15, *)
extension NSNotification.Name {
	
	public var cb: NotificationCenter.Publisher {
		NotificationCenter.Publisher(center: .default, name: self)
	}
	
}
