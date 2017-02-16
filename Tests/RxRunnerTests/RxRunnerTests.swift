import XCTest
@testable import RxRunner

class RxRunnerTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(RxRunner().text, "Hello, World!")
    }


    static var allTests : [(String, (RxRunnerTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
