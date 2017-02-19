import XCTest
@testable import AudioKit

class AudioKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(AudioKit().text, "Hello, World!")
    }


    static var allTests : [(String, (AudioKitTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
