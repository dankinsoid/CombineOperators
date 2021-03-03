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
		let single = Array<Int>().publisher.prefix(1).reduce([], { $0 + [$1] }).print()
		single.subscribe { _ in
			exp.fulfill()
		}
		waitForExpectations(timeout: 2, handler: nil)
	}
	
	private func get(text: String) {
		
	}
	
}

final class Button: UIButton {
	deinit {
		print("button deinit")
	}
}
