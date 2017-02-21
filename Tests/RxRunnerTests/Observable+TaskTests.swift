//
//  Observable+TaskTests.swift
//  RxRunner
//
//  Created by Scott Hoyt on 2/20/17.
//
//

import XCTest
@testable import RxRunner
import RxBlocking

class ObservableTaskTests: XCTestCase {
    func testJustExitStatus() throws {
        let script = try ScriptFile(commands: [
            "echo hello",
            "echo world"
        ])

        let exitStatus = try Task(launchPath: script.path).launch()
            .justExitStatus()
            .toBlocking()
            .toArray()

        XCTAssertEqual(exitStatus.count, 1)
        XCTAssertEqual(exitStatus[0], 0)
    }

    func testJustOutput() throws {
        let script = try ScriptFile(commands: [
            "echo hello",
            "sleep 0.1",
            "echo world",
            "sleep 0.1"
        ])

        let exitStatus = try Task(launchPath: script.path).launch()
            .justOutput()
            .toBlocking()
            .toArray()

        XCTAssertEqual(exitStatus.count, 2)
        XCTAssertEqual(exitStatus[0], "hello\n")
        XCTAssertEqual(exitStatus[1], "world\n")
    }

    static var allTests : [(String, (ObservableTaskTests) -> () throws -> Void)] {
        return [
            ("testJustExitStatus", testJustExitStatus),
            ("testJustOutput", testJustOutput),
        ]
    }
}
