import PackageDescription

let package = Package(
    name: "RxRunner",
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3)
    ]
)
