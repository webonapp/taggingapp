import Foundation

struct FindQuery {
    var text = ""
    var includeNotes = true
    var includeLabels = true
    var includeRowNames = true
    var flaggedOnly = false
}

struct FindResult: Identifiable {
    let id = UUID()
    let row: TimelineRow
    let instance: TimelineInstance
    let match: String
}

enum FindEngine {
    static func search(project: AnalysisProject, query: FindQuery) -> [FindResult] {
        let needle = query.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return project.timeline.rows.flatMap { row in
            row.instances.compactMap { instance in
                if query.flaggedOnly && !instance.isFlagged { return nil }
                let values = [
                    query.includeRowNames ? row.name : "",
                    query.includeNotes ? instance.note : "",
                    query.includeLabels ? instance.labels.map { $0.name }.joined(separator: " ") : ""
                ].joined(separator: " ").lowercased()
                guard needle.isEmpty || values.contains(needle) else { return nil }
                return FindResult(row: row, instance: instance, match: values)
            }
        }
    }
}
