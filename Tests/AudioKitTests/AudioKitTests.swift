import XCTest
@testable import AudioKit

final class AudioKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PlayerController().isPlaying, false)
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
