import XCTest
@testable import RemoteLogger

final class RemoteLoggerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(RemoteLogger().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
