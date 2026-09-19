import SwiftUI

struct FindWindowView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    @State private var query = FindQuery()
    @State private var results: [FindResult] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trova").font(.title2.bold())
                Spacer()
                Toggle("Solo flag", isOn: $query.flaggedOnly)
            }
            HStack {
                TextField("Codice, label, nota o riga", text: $query.text)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { runSearch() }
                Button("Cerca") { runSearch() }
            }
            HStack {
                Toggle("Righe", isOn: $query.includeRowNames)
                Toggle("Label", isOn: $query.includeLabels)
                Toggle("Note", isOn: $query.includeNotes)
                Spacer()
                Button("Esporta CSV") { try? CSVExporter.export(project: store.project) }
            }
            List(results) { result in
                Button {
                    currentTime = result.instance.startTime
                } label: {
                    HStack {
                        Text(result.row.name).frame(width: 230, alignment: .leading)
                        Text(timecode(result.instance.startTime)).monospacedDigit()
                        Text("–")
                        Text(timecode(result.instance.endTime)).monospacedDigit()
                        Spacer()
                        if !result.instance.note.isEmpty { Image(systemName: "note.text") }
                        if result.instance.isFlagged { Image(systemName: "flag.fill") }
                    }
                }
                .buttonStyle(.plain)
            }
            Text("Risultati: \(results.count)").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(minWidth: 760, minHeight: 420)
        .onAppear { runSearch() }
    }

    private func runSearch() { results = FindEngine.search(project: store.project, query: query) }
    private func timecode(_ value: Double) -> String { String(format: "%02d:%02d:%05.2f", Int(value) / 60, Int(value) % 60, value.truncatingRemainder(dividingBy: 60)) }
}
