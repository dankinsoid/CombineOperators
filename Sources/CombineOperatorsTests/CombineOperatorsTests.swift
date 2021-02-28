//
//  File.swift
//  
//
//  Created by Данил Войдилов on 28.02.2021.
//

import XCTest
import UIKit
import Combine
@testable import CombineOperators
@testable import CombineCocoa

final class CombineOperatorsTests: XCTestCase {
	
	@available(iOS 13.0, *)
	func test() {
		let button = Button()
		let exp = expectation(description: "")
		button.cb.tap => { exp.fulfill() }
		button.sendActions(for: .touchUpInside)
		waitForExpectations(timeout: 2, handler: nil)
		print("wait")
	}
	
}

final class Button: UIButton {
	deinit {
		print("button deinit")
	}
}
