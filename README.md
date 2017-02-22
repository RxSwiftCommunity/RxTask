# RxTask
An [RxSwift](https://github.com/ReactiveX/RxSwift) implementation of a command line task runner.

[![GitHub release](https://img.shields.io/github/release/RxSwiftCommunity/RxTask.svg)]()
[![Build Status](https://travis-ci.org/RxSwiftCommunity/RxTask.svg?branch=master)](https://travis-ci.org/RxSwiftCommunity/RxTask)
[![codecov](https://codecov.io/gh/RxSwiftCommunity/RxTask/branch/master/graph/badge.svg)](https://codecov.io/gh/RxSwiftCommunity/RxTask)
[![docs](https://cdn.rawgit.com/RxSwiftCommunity/RxTask/master/docs/badge.svg)](https://RxSwiftCommunity.github.io/RxTask/)
[![carthage compatible](https://img.shields.io/badge/carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![swift package manager compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
![platform macOS](https://img.shields.io/badge/platform-macOS-blue.svg)
[![language swift 3.0](https://img.shields.io/badge/language-Swift%203.0-orange.svg)](https://swift.org)

## Linux Compatibility

Currently, RxTask does not support Linux. RxTask relies on some functionality
in `Foundation` that is currently not available in the Linux port. This will be
re-evaluated after the Swift 3.1 release. PRs in this area are quite welcome! 👍

## Installation

### Carthage

```shell
github "RxSwiftCommunity/RxTask"
```

### SPM

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/RxSwiftCommunity/RxSwift.git", majorVersion: 0)
    ]
)
```

## Usage

### Create A Task

Creating a task is as simple as providing a `launchPath` to the executable.

```swift
let task = Task(launchPath: "/bin/ls")
```

Optionally, you can provide `arguments`, a `workingDirectory`, and an
`environment`.

```swift
let task = Task(launchPath: "/bin/echo", arguments: ["$MESSAGE"], environment: ["MESSAGE": "Hello World!"])
```

### Launch A Task

`Task`s can be launched with the `launch()` method. This produces a
self-contained process. This means the same task can be `launch()`ed multiple
times producing separate processes.

#### TaskEvent

The output of `launch()` is a `Observable<TaskEvent>`. `TaskEvent` is an `enum`
that is used to report significant events in the task lifetime. The possible
events are:

* `launch(command: String)`
* `stdOut(String)`
* `stdErr(String)`
* `exit(statusCode: Int)`

** Note: ** Currently an event is only considered successful if it exits with a
`statusCode` of 0. Other exit statuses will be considered a `TaskError`.

#### Filtering TaskEvents

If you are only concerned with whether a `Task` has completed successfully, you
can use the built-in operator `justExitStatus()`.

```swift
Task(launchPath: "/bin/ls").launch()
    .justExitStatus()
    .subscribe(onNext: { exitStatus in /* ... */ })
    .disposed(by: disposeBag)
```

Alternatively, if you are only interested in the output of a `Task`, you can use
the operator `justOutput()`. *This will send the output of both `stdout` and
`stderr`*.

```swift
Task(launchPath: "/bin/ls").launch()
    .justOutput()
    .subscribe(onNext: { output in /* ... */ })
    .disposed(by: disposeBag)
```

#### TaskError

`TaskError` is an `Error` that will be emitted under the following situations:

* `uncaughtSignal`: The `Task` terminated with an uncaught signal (e.g. `SIGINT`).
* `exit(statusCode: Int)`: The `Task` exited with a non-zero exit code.

## API Reference

Full docs can be found [here](https://RxSwiftCommunity.github.io/RxTask/).
