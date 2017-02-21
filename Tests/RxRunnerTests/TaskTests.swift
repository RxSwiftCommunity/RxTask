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

class TaskTests: XCTestCase {
    func testStdOut() throws {
        let script = try ScriptFile(commands: [
                "echo hello world",
                "sleep 0.1"
            ])

        let events = try getEvents(for: script)

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

        let events = try getEvents(for: script)

        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events[0], .start(command: script.path))
        XCTAssertEqual(events[1], .stdErr("hello world\n"))
        XCTAssertEqual(events[2], .exit(statusCode: 0))
    }

    func testExitsWithFailingStatusErrors() throws {
        let script = try ScriptFile(commands: ["exit 100"])

        do {
            _ = try getEvents(for: script)

            // If we get this far it is a failure
            XCTFail()
        } catch {
            if let error = error as? TaskError {
                XCTAssertEqual(error, .exit(statusCode: 100))
            } else {
                XCTFail()
            }
        }
    }

    func testUncaughtSignalErrors() throws {
        let script = try ScriptFile(commands: [
                "kill $$",
                "sleep 10"
            ])

        do {
            _ = try getEvents(for: script)

            // If we get this far it is a failure
            XCTFail()
        } catch {
            if let error = error as? TaskError {
                XCTAssertEqual(error, .uncaughtSignal)
            } else {
                XCTFail()
            }
        }
    }

    static var allTests : [(String, (TaskTests) -> () throws -> Void)] {
        return [
            ("testStdOut", testStdOut),
            ("testStdErr", testStdErr),
            ("testExitsWithFailingStatusErrors", testExitsWithFailingStatusErrors),
            ("testUncaughtSignalErrors", testUncaughtSignalErrors)
        ]
    }

    // MARK: Helpers

    func getEvents(for script: ScriptFile) throws -> [TaskEvent] {
        return try Task(launchPath: script.path).launch()
            .toBlocking()
            .toArray()
    }
}
