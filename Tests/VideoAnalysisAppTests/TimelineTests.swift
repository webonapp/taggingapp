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

    func testFindEngineFindsLabelsAndNotes() {
        var project = AnalysisProject(name: "Find")
        var row = TimelineRow(name: "Pressing")
        row.instances = [TimelineInstance(startTime: 1, endTime: 3, labels: [TimelineLabel(name: "Occasione creata", group: "03. Occasioni")], note: "azione importante")]
        project.timeline.rows = [row]
        XCTAssertEqual(FindEngine.search(project: project, query: FindQuery(text: "occasione")).count, 1)
        XCTAssertEqual(FindEngine.search(project: project, query: FindQuery(text: "importante")).count, 1)
    }
}
