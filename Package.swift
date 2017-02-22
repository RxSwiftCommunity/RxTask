import PackageDescription

let package = Package(
    name: "RxTask",
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3, minorVersion: 2)
    ]
)
