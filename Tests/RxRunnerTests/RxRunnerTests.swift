import XCTest
@testable import RxRunner
import RxSwift
import RxBlocking

class RxRunnerTests: XCTestCase {
    func testStdOut() throws {
        let script = try createScript(commands: [
                "echo hello world",
                "sleep 0.1"
            ])

        let events = try Task.init(launchPath: script.path).launch()
            .toBlocking()
            .toArray()

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .start(command: script.path))
        XCTAssertEqual(events[1], .stdOut("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))

        try FileManager.default.removeItem(at: script)
    }

    func testStdErr() throws {
        let script = try createScript(commands: [
            "echo hello world 1>&2",
            "sleep 0.1"
            ])

        let events = try Task.init(launchPath: script.path).launch()
            .toBlocking()
            .toArray()

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .start(command: script.path))
        XCTAssertEqual(events[1], .stdErr("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))

        try FileManager.default.removeItem(at: script)
    }

    static var allTests : [(String, (RxRunnerTests) -> () throws -> Void)] {
        return [
            ("testStdOut", testStdOut),
            ("testStdErr", testStdErr)
        ]
    }

    func createScript(commands: [String]) throws -> URL {
        let fileName = UUID().uuidString + ".sh"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)

        let shebang = "#!/bin/bash"
        let contents = ([shebang] + commands).joined(separator: "\n")
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)

        let permissions = NSNumber(value: 0o0770).int16Value
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: fileURL.path)

        return fileURL
    }
}
