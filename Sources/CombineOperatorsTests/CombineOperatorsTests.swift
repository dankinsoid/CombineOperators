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
		let exp = [expectation(description: "0"), expectation(description: "1")]
		let date = Date()
		[0, 1].publisher.interval(0.5) => { exp[$0].fulfill(); print(Date().timeIntervalSince(date)) }
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
