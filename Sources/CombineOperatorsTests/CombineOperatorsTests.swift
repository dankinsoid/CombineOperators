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
		let exp = expectation(description: "0")
		var count = 0
		DispatchSource.Timer(1, count: 1) => { _ in
			count += 1
			exp.fulfill()
		}
		waitForExpectations(timeout: 2, handler: nil)
		XCTAssert(count == 1, "\(count)")
	}
	
}

final class Button: UIButton {
	deinit {
		print("button deinit")
	}
}
