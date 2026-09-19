import Foundation
import AppKit

@MainActor
enum CSVExporter {
    static func export(project: AnalysisProject) throws -> URL {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(project.name)-timeline.csv"
        guard panel.runModal() == .OK, let url = panel.url else { throw ExportError.cancelled }
        var rows = ["row,start_time,end_time,duration,labels,note,flagged"]
        for row in project.timeline.rows {
            for instance in row.instances {
                let labels = instance.labels.map { $0.name }.joined(separator: " | ")
                rows.append([row.name, String(instance.startTime), String(instance.endTime), String(instance.duration), labels, instance.note, String(instance.isFlagged)].map(csv).joined(separator: ","))
            }
        }
        try Data((rows.joined(separator: "\n") + "\n").utf8).write(to: url, options: .atomic)
        return url
    }

    private static func csv(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    enum ExportError: LocalizedError { case cancelled; var errorDescription: String? { "Esportazione annullata" } }
}
