import XCTest
@testable import ComponentKit

final class ComponentKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ComponentKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
