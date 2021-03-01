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
		
		let subject = CurrentValueSubject<String, Error>("")
		let label = UILabel()
		subject => label.cb.text
		
		_ = cb.weak(It.test)
		
		print("wait")
	}
	
	
}

final class Button: UIButton {
	deinit {
		print("button deinit")
	}
}
