//
//  Runner.swift
//  RxRunner
//
//  Created by Scott Hoyt on 2/18/17.
//
//

import Foundation
import RxSwift

public enum TaskEvent {
    case start(command: String)
    case stdOut(String)
    case stdErr(String)
    case exit(statusCode: Int)
}

extension TaskEvent: Equatable {
    public static func == (lhs: TaskEvent, rhs: TaskEvent) -> Bool {
        switch (lhs, rhs) {
        case let (.start(left), .start(right)):
            return left == right
        case let (.stdOut(left), .stdOut(right)):
            return left == right
        case let (.stdErr(left), .stdErr(right)):
            return left == right
        case let (.exit(left), .exit(right)):
            return left == right
        default:
            return false
        }
    }
}

public struct Task {
    let launchPath: String
    let arguments: [String]

    public init(launchPath: String, arguments: [String] = []) {
        self.launchPath = launchPath
        self.arguments = arguments
    }

    public func launch() -> Observable<TaskEvent> {
        let process = Process()
        process.launchPath = self.launchPath
        process.arguments = self.arguments

        let command = ([launchPath] + arguments).joined(separator: " ")

        return Observable.create { observer in
            process.standardOutput = self.pipe { observer.onNext(.stdOut($0)) }
            process.standardError = self.pipe { observer.onNext(.stdErr($0)) }

            process.terminationHandler = self.terminationHandler(observer: observer)

            observer.onNext(.start(command: command))
            process.launch()

            return Disposables.create {
                if process.isRunning {
                    process.terminate()
                }
            }
        }
    }

    private func terminationHandler(observer: AnyObserver<TaskEvent>) -> (Process) -> Void {
        // Handle process termination and determine if it was a normal exit
        // or an error.
        return { process in
            switch process.terminationReason {
            case .exit:
                observer.onNext(.exit(statusCode: Int(process.terminationStatus)))
                observer.onCompleted()
            case .uncaughtSignal:
                observer.onError(NSError()) // TODO: Need to put a real error here
            }
        }
    }

    private func pipe(withHandler handler: @escaping (String) -> Void) -> Pipe {
        let pipe = Pipe()

        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            if let string = String(data: fileHandle.availableData, encoding: .utf8) {
                handler(string)
            }
        }

        return pipe
    }
}