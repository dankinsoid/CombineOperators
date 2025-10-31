import Foundation
import Combine

extension NSNotification.Name {
	
	public var cb: NotificationCenter.Publisher {
		NotificationCenter.Publisher(center: .default, name: self)
	}
}
