import XCTest
@testable import RxRunner
import RxSwift
import RxBlocking

class RxRunnerTests: XCTestCase {
    func testExample() throws {
        let events = try Task(launchPath: "/bin/echo", arguments: ["hello", "world"]).launch()
            .toBlocking()
            .toArray()

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .start(command: "/bin/echo hello world"))
        XCTAssertEqual(events[1], .stdOut("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))
    }

    static var allTests : [(String, (RxRunnerTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
