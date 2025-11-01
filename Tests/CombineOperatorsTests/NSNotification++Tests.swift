import Combine
@testable import CombineOperators
import Foundation
import Testing
#if canImport(UIKit)
import UIKit
#endif

@Suite("NSNotification++ Tests")
struct NSNotificationTests {

	// MARK: - Basic Behavior

	@Test("NSNotification.Name.cb creates publisher for default center")
	func notificationNameCbCreatesPublisherForDefaultCenter() async {
		let expectation = Expectation<Notification>(limit: 1)

		let notificationName = Notification.Name("TestNotification")
		let cancellable = notificationName.cb.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil)

		let received = await expectation.values
		#expect(received.count == 1)
		#expect(received.first?.name == notificationName)

		cancellable.cancel()
	}

	@Test("NSNotification.Name.cb receives notification with object")
	func notificationNameCbReceivesNotificationWithObject() async {
		let expectation = Expectation<Notification>(limit: 1)

		let notificationName = Notification.Name("TestNotificationWithObject")
		let testObject = NSObject()

		let cancellable = notificationName.cb.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: testObject)

		let received = await expectation.values
		#expect(received.count == 1)
		#expect(received.first?.name == notificationName)
		#expect(received.first?.object as? NSObject === testObject)

		cancellable.cancel()
	}

	@Test("NSNotification.Name.cb receives notification with userInfo")
	func notificationNameCbReceivesNotificationWithUserInfo() async {
		let expectation = Expectation<Notification>(limit: 1)

		let notificationName = Notification.Name("TestNotificationWithUserInfo")
		let userInfo = ["key": "value"]

		let cancellable = notificationName.cb.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil, userInfo: userInfo)

		let received = await expectation.values
		#expect(received.count == 1)
		#expect(received.first?.userInfo?["key"] as? String == "value")

		cancellable.cancel()
	}

	// MARK: - Multiple Notifications

	@Test("NSNotification.Name.cb receives multiple notifications")
	func notificationNameCbReceivesMultipleNotifications() async {
		let expectation = Expectation<Notification>(limit: 3)

		let notificationName = Notification.Name("MultipleTestNotification")
		let cancellable = notificationName.cb.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil)
		NotificationCenter.default.post(name: notificationName, object: nil)
		NotificationCenter.default.post(name: notificationName, object: nil)

		let received = await expectation.values
		#expect(received.count == 3)

		cancellable.cancel()
	}

	@Test("NSNotification.Name.cb filters by notification name")
	func notificationNameCbFiltersByName() async {
		let expectation = Expectation<Notification>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let targetNotification = Notification.Name("TargetNotification")
		let otherNotification = Notification.Name("OtherNotification")

		let cancellable = targetNotification.cb.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: otherNotification, object: nil)
		NotificationCenter.default.post(name: targetNotification, object: nil)

		let received = await expectation.values
		#expect(received.count == 1)
		#expect(received.first?.name == targetNotification)

		cancellable.cancel()
	}

	// MARK: - Cancellation

	@Test("NSNotification.Name.cb respects cancellation")
	func notificationNameCbRespectsCancellation() async {
		let expectation = Expectation<Notification>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let notificationName = Notification.Name("CancellableNotification")
		let cancellable = notificationName.cb.sink { expectation.fulfill($0) }

		cancellable.cancel()

		NotificationCenter.default.post(name: notificationName, object: nil)

		let received = await expectation.values
		#expect(received.isEmpty)
	}

	// MARK: - Integration with Operators

	@Test("NSNotification.Name.cb works with map operator")
	func notificationNameCbWorksWithMap() async {
		let expectation = Expectation<String>(limit: 1)

		let notificationName = Notification.Name("MapTestNotification")
		let cancellable = notificationName.cb
			.map { $0.name.rawValue }
			.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil)

		let received = await expectation.values
		#expect(received == ["MapTestNotification"])

		cancellable.cancel()
	}

	@Test("NSNotification.Name.cb works with filter operator")
	func notificationNameCbWorksWithFilter() async {
		let expectation = Expectation<Notification>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let notificationName = Notification.Name("FilterTestNotification")
		let testObject = NSObject()

		let cancellable = notificationName.cb
			.filter { $0.object != nil }
			.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil)
		NotificationCenter.default.post(name: notificationName, object: testObject)

		let received = await expectation.values
		#expect(received.count == 1)
		#expect(received.first?.object as? NSObject === testObject)

		cancellable.cancel()
	}

	@Test("NSNotification.Name.cb works with compactMap")
	func notificationNameCbWorksWithCompactMap() async {
		let expectation = Expectation<String>(limit: 1)

		let notificationName = Notification.Name("CompactMapTestNotification")
		let cancellable = notificationName.cb
			.compactMap { $0.userInfo?["value"] as? String }
			.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil, userInfo: nil)
		NotificationCenter.default.post(name: notificationName, object: nil, userInfo: ["value": "test"])

		let received = await expectation.values
		#expect(received == ["test"])

		cancellable.cancel()
	}

	// MARK: - Multiple Subscribers

	@Test("NSNotification.Name.cb supports multiple subscribers")
	func notificationNameCbSupportsMultipleSubscribers() async {
		let expectation1 = Expectation<Notification>(limit: 1)
		let expectation2 = Expectation<Notification>(limit: 1)

		let notificationName = Notification.Name("MultiSubscriberNotification")

		let cancellable1 = notificationName.cb.sink { expectation1.fulfill($0) }
		let cancellable2 = notificationName.cb.sink { expectation2.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil)

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1.count == 1)
		#expect(received2.count == 1)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Standard Notifications

	#if canImport(UIKit)
	@Test("NSNotification.Name.cb works with UIKit notifications")
	func notificationNameCbWorksWithUIKitNotifications() async {
		let expectation = Expectation<Notification>(limit: 1, timeLimit: 0.5, failOnTimeout: false)

		let cancellable = UIApplication.didBecomeActiveNotification.cb.sink {
			expectation.fulfill($0)
		}

		// Posting a UIKit notification in tests
		NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)

		let received = await expectation.values
		#expect(received.count == 1)

		cancellable.cancel()
	}
	#endif

	// MARK: - Thread Safety

	@Test("NSNotification.Name.cb handles concurrent posts")
	func notificationNameCbHandlesConcurrentPosts() async {
		let expectation = Expectation<Notification>(limit: 10)

		let notificationName = Notification.Name("ConcurrentNotification")
		let cancellable = notificationName.cb.sink { expectation.fulfill($0) }

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< 10 {
				group.addTask {
					NotificationCenter.default.post(name: notificationName, object: nil)
				}
			}
		}

		let received = await expectation.values
		#expect(received.count == 10)

		cancellable.cancel()
	}

	// MARK: - Edge Cases

	@Test("NSNotification.Name.cb handles rapid subscribe/unsubscribe")
	func notificationNameCbHandlesRapidSubscribeUnsubscribe() async {
		let notificationName = Notification.Name("RapidSubscribeNotification")

		for _ in 0 ..< 10 {
			let cancellable = notificationName.cb.sink { _ in }
			cancellable.cancel()
		}

		// Should not crash or leak
		#expect(true)
	}

	@Test("NSNotification.Name.cb equivalent to NotificationCenter.Publisher")
	func notificationNameCbEquivalentToNotificationCenterPublisher() async {
		let expectation1 = Expectation<Notification>(limit: 1)
		let expectation2 = Expectation<Notification>(limit: 1)

		let notificationName = Notification.Name("EquivalenceTestNotification")

		let cancellable1 = notificationName.cb.sink { expectation1.fulfill($0) }
		let cancellable2 = NotificationCenter.default.publisher(for: notificationName)
			.sink { expectation2.fulfill($0) }

		NotificationCenter.default.post(name: notificationName, object: nil)

		let received1 = await expectation1.values
		let received2 = await expectation2.values

		#expect(received1.count == 1)
		#expect(received2.count == 1)
		#expect(received1.first?.name == received2.first?.name)

		cancellable1.cancel()
		cancellable2.cancel()
	}

	// MARK: - Custom Notification Names

	@Test("NSNotification.Name.cb works with custom notification names")
	func notificationNameCbWorksWithCustomNames() async {
		let expectation = Expectation<Notification>(limit: 1)

		let customName = Notification.Name("com.example.customNotification")
		let cancellable = customName.cb.sink { expectation.fulfill($0) }

		NotificationCenter.default.post(name: customName, object: nil)

		let received = await expectation.values
		#expect(received.count == 1)
		#expect(received.first?.name == customName)

		cancellable.cancel()
	}
}
