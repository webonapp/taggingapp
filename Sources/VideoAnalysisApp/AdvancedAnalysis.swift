import Foundation

struct DatabaseEntry: Identifiable {
    let id: UUID
    let timelineName: String
    let rowName: String
    let startTime: Double
    let endTime: Double
    let labels: [TimelineLabel]
    let note: String
    let flagged: Bool
}

struct MatrixCell: Identifiable {
    let id = UUID()
    let rowLabel: String
    let columnLabel: String
    let count: Int
}

struct ReportSummary {
    let totalInstances: Int
    let totalDuration: Double
    let flaggedInstances: Int
    let rowCounts: [(name: String, count: Int)]
    let labelCounts: [(name: String, count: Int)]
}

enum AnalysisEngine {
    static func database(from project: AnalysisProject) -> [DatabaseEntry] {
        project.timeline.rows.flatMap { row in
            row.instances.map { instance in
                DatabaseEntry(id: instance.id, timelineName: project.name, rowName: row.name, startTime: instance.startTime, endTime: instance.endTime, labels: instance.labels, note: instance.note, flagged: instance.isFlagged)
            }
        }.sorted { $0.startTime < $1.startTime }
    }

    static func matrix(from project: AnalysisProject) -> [MatrixCell] {
        let entries = database(from: project)
        let rowLabels = Array(Set(entries.map(\.rowName))).sorted()
        let labels = Array(Set(entries.flatMap { $0.labels.map(\.name) })).sorted()
        return rowLabels.flatMap { row in
            labels.map { label in
                MatrixCell(rowLabel: row, columnLabel: label, count: entries.filter { $0.rowName == row && $0.labels.contains(where: { $0.name == label }) }.count)
            }
        }
    }

    static func report(from project: AnalysisProject) -> ReportSummary {
        let entries = database(from: project)
        let rowCounts = Dictionary(grouping: entries, by: \.rowName).map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 }
        let labelCounts = Dictionary(grouping: entries.flatMap { $0.labels.map(\.name) }, by: { $0 }).map { ($0.key, $0.value.count) }.sorted { $0.0 < $1.0 }
        return ReportSummary(totalInstances: entries.count, totalDuration: entries.reduce(0) { $0 + ($1.endTime - $1.startTime) }, flaggedInstances: entries.filter(\.flagged).count, rowCounts: rowCounts, labelCounts: labelCounts)
    }
}
