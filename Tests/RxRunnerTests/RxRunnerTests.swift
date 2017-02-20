import XCTest
@testable import RxRunner
import RxSwift
import RxBlocking

class ScriptFile {
    private let url: URL

    var path: String {
        return url.path
    }

    init(commands: [String]) throws {
        let fileName = UUID().uuidString + ".sh"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent(fileName)

        let shebang = "#!/bin/bash"
        let contents = ([shebang] + commands).joined(separator: "\n")
        try contents.write(to: fileURL, atomically: true, encoding: .utf8)

        let permissions = Int16(0o0770)
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: fileURL.path)
        url = fileURL
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}

class RxRunnerTests: XCTestCase {
    func testStdOut() throws {
        let script = try ScriptFile(commands: [
                "echo hello world",
                "sleep 0.1"
            ])

        let events = try Task(launchPath: script.path).launch()
            .toBlocking()
            .toArray()

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .start(command: script.path))
        XCTAssertEqual(events[1], .stdOut("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))
    }

    func testStdErr() throws {
        let script = try ScriptFile(commands: [
            "echo hello world 1>&2",
            "sleep 0.1"
            ])

        let events = try Task(launchPath: script.path).launch()
            .toBlocking()
            .toArray()

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .start(command: script.path))
        XCTAssertEqual(events[1], .stdErr("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))
    }

    static var allTests : [(String, (RxRunnerTests) -> () throws -> Void)] {
        return [
            ("testStdOut", testStdOut),
            ("testStdErr", testStdErr)
        ]
    }
}
