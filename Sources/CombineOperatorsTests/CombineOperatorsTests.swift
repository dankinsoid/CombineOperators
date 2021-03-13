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
		let exp1 = expectation(description: "0")
		let exp2 = expectation(description: "0")
		var date1 = Date()
		var date2 = Date()
		DispatchQueue.global().async {
			Just(4).receive(on: DispatchQueue.main).subscribe { _ in
				exp2.fulfill()
				date1 = Date()
			}
			Just(4).receive(on: MainSyncScheduler()).subscribe { _ in
				exp1.fulfill()
				date2 = Date()
			}
		}
		waitForExpectations(timeout: 2, handler: nil)
		print(date2 > date1)
	}
}
