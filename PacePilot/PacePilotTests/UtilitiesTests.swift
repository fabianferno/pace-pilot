import XCTest
@testable import PacePilot

final class PaceFormatterTests: XCTestCase {
    func test_formatsPaceFromSecondsPerKm() {
        XCTAssertEqual(PaceFormatter.format(secondsPerKm: 272), "4:32")
    }
    func test_formatsSubFiveMinutePace() {
        XCTAssertEqual(PaceFormatter.format(secondsPerKm: 240), "4:00")
    }
    func test_formatsSlowPace() {
        XCTAssertEqual(PaceFormatter.format(secondsPerKm: 450), "7:30")
    }
}

final class RunTimeFormatterTests: XCTestCase {
    func test_formatsUnderOneHour() {
        XCTAssertEqual(RunTimeFormatter.format(seconds: 1425), "23:45")
    }
    func test_formatsOverOneHour() {
        XCTAssertEqual(RunTimeFormatter.format(seconds: 5025), "1:23:45")
    }
}
