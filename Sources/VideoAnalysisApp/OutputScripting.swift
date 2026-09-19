import Foundation

struct OutputMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

enum OutputScriptEngine {
    static func execute(_ script: String, project: AnalysisProject) -> [OutputMetric] {
        let entries = AnalysisEngine.database(from: project)
        return script.split(whereSeparator: \.isNewline).compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#") else { return nil }
            let parts = line.split(separator: " ", maxSplits: 2).map(String.init)
            guard let command = parts.first?.uppercased() else { return nil }
            switch command {
            case "COUNT":
                return OutputMetric(title: parts.dropFirst().joined(separator: " ").isEmpty ? "Istanze" : parts.dropFirst().joined(separator: " "), value: String(entries.count))
            case "DURATION":
                return OutputMetric(title: parts.dropFirst().joined(separator: " ").isEmpty ? "Durata" : parts.dropFirst().joined(separator: " "), value: String(format: "%.2f s", entries.reduce(0) { $0 + $1.endTime - $1.startTime }))
            case "COUNT_LABEL":
                guard parts.count >= 2 else { return nil }
                let label = parts.dropFirst().joined(separator: " ")
                return OutputMetric(title: label, value: String(entries.filter { $0.labels.contains(where: { $0.name.caseInsensitiveCompare(label) == .orderedSame }) }.count))
            case "COUNT_ROW":
                guard parts.count >= 2 else { return nil }
                let row = parts.dropFirst().joined(separator: " ")
                return OutputMetric(title: row, value: String(entries.filter { $0.rowName.caseInsensitiveCompare(row) == .orderedSame }.count))
            default:
                return OutputMetric(title: "Script non riconosciuto", value: command)
            }
        }
    }
}
