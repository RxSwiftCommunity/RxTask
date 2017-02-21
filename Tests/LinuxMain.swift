import XCTest
@testable import RxRunnerTests

XCTMain([
     testCase(TaskTests.allTests),
     testCase(ObservableTaskTests.allTests)
])
