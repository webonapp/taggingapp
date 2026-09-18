import XCTest
@testable import VideoAnalysisApp

final class TimelineTests: XCTestCase {
    func testInstanceDuration() {
        let instance = TimelineInstance(startTime: 2.5, endTime: 5.0)
        XCTAssertEqual(instance.duration, 2.5)
    }

    func testProjectRoundTrip() throws {
        var project = AnalysisProject(name: "Test")
        project.timeline.rows = [TimelineRow(name: "Pressing", colorHex: "#9F1503")]
        let data = try JSONEncoder.projectEncoder.encode(project)
        let decoded = try JSONDecoder.projectDecoder.decode(AnalysisProject.self, from: data)
        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.timeline.rows.first?.name, "Pressing")
    }
}
