import XCTest
@testable import EventManager

final class EventManagerTests: XCTestCase {
    struct TestObject: Codable, Equatable {
        let count: Int
        let description: String
    }

    func testSubscribe() {
        let manager = EventManager.shared
        let eventObject = TestObject(count: 3, description: "MyObject")
        let expectation = self.expectation(description: "handler is called")
        let eventName = "TestSubscribe"
        
        expectation.expectedFulfillmentCount = 1
        let _ = manager.subscribe(eventName) { (name: String, object: TestObject) in
            XCTAssertEqual(name, eventName)
            XCTAssertEqual(object.count, 3)
            XCTAssertEqual(object.description, "MyObject")

            expectation.fulfill()
        }
        manager.publish(eventName, sender: "Test", object: eventObject)
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testMultipleSubscribers() {
        let manager = EventManager.shared
        let eventObject = TestObject(count: 3, description: "MyObject")
        let expectation = self.expectation(description: "handler is called")
        let eventName = "testMultipleSubscribers"
        let otherEventName = "testMultipleSubscribersOther"

        expectation.expectedFulfillmentCount = 2
        let _ = manager.subscribe(eventName) { (name: String, object: TestObject) in
            XCTAssertEqual(name, eventName)
            XCTAssertEqual(object.count, 3)
            XCTAssertEqual(object.description, "MyObject")

            expectation.fulfill()
        }
        let _ = manager.subscribe(eventName) { (name: String, object: TestObject) in
            XCTAssertEqual(name, eventName)
            XCTAssertEqual(object.count, 3)
            XCTAssertEqual(object.description, "MyObject")

            expectation.fulfill()
        }
        let _ = manager.subscribe(otherEventName) { (name: String, object: TestObject) in
            XCTAssertEqual(name, otherEventName)
            XCTAssertEqual(object.count, 3)
            XCTAssertEqual(object.description, "MyObject")

            expectation.fulfill()
        }
        manager.publish(eventName, sender: "Test", object: eventObject)
        
        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testUnsubscribe() {
        let manager = EventManager.shared
        let eventObject = TestObject(count: 3, description: "MyObject")
        let expectation = self.expectation(description: "handler is called")
        let eventName = "TestUnsubscribe"

        expectation.expectedFulfillmentCount = 1
        let token = manager.subscribe(eventName) { (name: String, object: TestObject) in
            XCTAssertEqual(name, eventName)
            XCTAssertEqual(object.count, 3)
            XCTAssertEqual(object.description, "MyObject")

            expectation.fulfill()
        }
        manager.publish(eventName, sender: "Test", object: eventObject)
        
        manager.unsubscribe(eventName, token: token)
        manager.publish(eventName, sender: "Test", object: eventObject)

        waitForExpectations(timeout: 0.1, handler: nil)
    }

    func testUnsubscribeAll() {
        let manager = EventManager.shared
        let eventObject = TestObject(count: 3, description: "MyObject")
        let expectation = self.expectation(description: "handler is called")
        let eventName = "TestUnsubscribeAll"

        expectation.expectedFulfillmentCount = 1
        let token = manager.subscribe(eventName) { (name: String, object: TestObject) in
            XCTAssertEqual(name, eventName)
            XCTAssertEqual(object.count, 3)
            XCTAssertEqual(object.description, "MyObject")

            expectation.fulfill()
        }
        manager.publish(eventName, sender: "Test", object: eventObject)
        
        manager.unsubscribe(eventName, token: token)
        manager.publish(eventName, sender: "Test", object: eventObject)

        waitForExpectations(timeout: 0.1, handler: nil)
    }
    
    func testPublish() {
        let manager = EventManager.shared
        let eventObject = TestObject(count: 3, description: "MyObject")
        let eventName = "TestPublish"

        manager.clearEventHistory()
        manager.publish(eventName, sender: "Test", object: eventObject)
        XCTAssertEqual(manager.publishedEvents.count, 1)
        XCTAssertEqual(manager.publishedEvents[0].name, eventName)
        XCTAssertEqual(manager.publishedEvents[0].data, "{\n  \"count\" : 3,\n  \"description\" : \"MyObject\"\n}")
    }
}
