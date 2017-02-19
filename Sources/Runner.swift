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

public struct Task {
    let launchPath: String
    let arguments: [String]

    public init(launchPath: String, arguments: [String] = []) {
        self.launchPath = launchPath
        self.arguments = arguments
    }

    public func launch() -> Observable<TaskEvent> {
        return Observable.create { observer in
            let process = Process()
            process.launchPath = self.launchPath
            process.arguments = self.arguments

            process.terminationHandler = self.terminationHandler(observer: observer)

            let command = ([self.launchPath] + self.arguments).joined(separator: " ")
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
        // Handle process termination and determin if it was a normal exit
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
}
