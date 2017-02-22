//
//  Runner.swift
//  RxTask
//
//  Created by Scott Hoyt on 2/18/17.
//
//

import Foundation
import RxSwift

#if os(Linux)
    typealias Process = Foundation.Task

    extension Process {
        var isRunning: Bool {
            return running
        }
    }
#endif

/// Event emitted by a launched `Task`.
public enum TaskEvent {

    /// The `Task` has launched.
    case launch(command: String)

    /// The `Task` has output to `stdout`.
    case stdOut(String)

    /// The `Task` has output to `stderr`.
    case stdErr(String)

    /// The `Task` exited successfully.
    case exit(statusCode: Int)
}

extension TaskEvent: Equatable {

    /// Equates two `TaskEvent`s.
    public static func == (lhs: TaskEvent, rhs: TaskEvent) -> Bool {
        switch (lhs, rhs) {
        case let (.launch(left), .launch(right)):
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

/// An error encountered in the execution of a `Task`.
public enum TaskError: Error {

    /// Cannot encode input `String` into `Data` (using UTF8)
    case cannotEncodeInput(String)

    /// An uncaught signal was encountered.
    case uncaughtSignal

    /// The `Task` exited unsuccessfully.
    case exit(statusCode: Int)
}

extension TaskError: Equatable {

    /// Equates two `TaskError`s.
    public static func == (lhs: TaskError, rhs: TaskError) -> Bool {
        switch (lhs, rhs) {
        case let (.cannotEncodeInput(left), .cannotEncodeInput(right)):
            return left == right
        case (.uncaughtSignal, .uncaughtSignal):
            return true
        case let (.exit(left), .exit(right)):
            return left == right
        default:
            return false
        }
    }
}

/// Encapsulates launching a RxSwift powered command line task.
public struct Task {

    /// The location of the executable.
    let launchPath: String

    /// The arguments to be passed to the executable.
    let arguments: [String]

    /// The working directory of the task. If `nil`, this will inherit from the parent process.
    let workingDirectory: String?

    /// The environment to launch the task with. If `nil`, this will inherit from the parent process.
    let environment: [String: String]?

    /// The `Observable` that supplies the `stdin`
    let stdIn: Observable<String>?

    private let disposeBag = DisposeBag()

    /**
     Create a new task.

     - parameters:
       - launchPath: The location of the executable.
       - arguments: The arguments to be passed to the executable.
       - stdIn: The `Observable` that supplies `stdin`.
       - workingDirectory: The working directory of the task. If not used, this will inherit from the parent process.
       - environment: The environment to launch the task with. If not used, this will inherit from the parent process.
    */
    public init(
        launchPath: String,
        arguments: [String] = [],
        stdIn: Observable<String>? = nil,
        workingDirectory: String? = nil,
        environment: [String: String]? = nil) {
        self.launchPath = launchPath
        self.arguments = arguments
        self.workingDirectory = workingDirectory
        self.environment = environment
        self.stdIn = stdIn
    }

    /// Launch the `Task`.
    public func launch() -> Observable<TaskEvent> {
        let process = Process()
        process.launchPath = self.launchPath
        process.arguments = self.arguments

        if let workingDirectory = workingDirectory { process.currentDirectoryPath = workingDirectory }
        if let environment = environment { process.environment = environment }

        return Observable.create { observer in
            process.standardOutput = self.outPipe { observer.onNext(.stdOut($0)) }
            process.standardError = self.outPipe { observer.onNext(.stdErr($0)) }

            if let stdIn = self.stdIn {
                process.standardInput = self.inPipe(stdIn: stdIn, errorHandler: observer.onError)
            }

            process.terminationHandler = self.terminationHandler(observer: observer)

            observer.onNext(.launch(command: self.description))
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
                if process.terminationStatus == 0 {
                    observer.onNext(.exit(statusCode: Int(process.terminationStatus)))
                    observer.onCompleted()
                } else {
                    observer.onError(TaskError.exit(statusCode: Int(process.terminationStatus)))
                }
            case .uncaughtSignal:
                observer.onError(TaskError.uncaughtSignal)
            }
        }
    }

    private func outPipe(withHandler handler: @escaping (String) -> Void) -> Pipe {
        let pipe = Pipe()

        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            if let string = String(data: fileHandle.availableData, encoding: .utf8) {
                handler(string)
            }
        }

        return pipe
    }

    private func inPipe(stdIn: Observable<String>, errorHandler: @escaping (Error) -> Void) -> Pipe {
        let pipe = Pipe()

        stdIn
            .subscribe(onNext: { input in
                guard let data = input.data(using: .utf8) else {
                    errorHandler(TaskError.cannotEncodeInput(input))
                    return
                }
                pipe.fileHandleForWriting.write(data)
            })
            .disposed(by: disposeBag)

        return pipe
    }
}

extension Task: CustomStringConvertible {
    public var description: String {
        return ([launchPath] + arguments).joined(separator: " ")
    }
}
