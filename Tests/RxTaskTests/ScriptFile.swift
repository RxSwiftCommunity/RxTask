//
//  ScriptFile.swift
//  RxTask
//
//  Created by Scott Hoyt on 2/20/17.
//
//

import Foundation

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
