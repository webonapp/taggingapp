import SwiftUI
import AVKit

struct ClipInspectorView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var startText = "0"
    @State private var endText = "0"
    @State private var note = ""
    @State private var preRoll = 0.0
    @State private var postRoll = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Inspector taglio").font(.title2.bold())
            if let selected = store.selectedInstances().first {
                Text(selected.0.name).font(.headline)
                HStack {
                    TextField("In", text: $startText).textFieldStyle(.roundedBorder)
                    TextField("Out", text: $endText).textFieldStyle(.roundedBorder)
                }
                HStack {
                    Stepper("Pre-roll \(preRoll, specifier: "%.1f")s", value: $preRoll, in: 0...30, step: 0.1)
                    Stepper("Post-roll \(postRoll, specifier: "%.1f")s", value: $postRoll, in: 0...30, step: 0.1)
                }
                TextEditor(text: $note).frame(minHeight: 90).border(.secondary.opacity(0.3))
                HStack {
                    Button("Applica In/Out") { applyTimes() }
                    Button("Salva nota") { store.addNoteToSelected(note) }
                    Button("Invia all'Ordinatore") { store.addSelectedToPlaylist() }
                }
            } else {
                ContentUnavailableView("Nessun taglio selezionato", systemImage: "scissors")
            }
            Spacer()
        }
        .padding()
        .frame(minWidth: 620, minHeight: 300)
        .onAppear { refresh() }
    }

    private func refresh() {
        guard let selected = store.selectedInstances().first else { return }
        startText = String(format: "%.3f", selected.1.startTime)
        endText = String(format: "%.3f", selected.1.endTime)
        note = selected.1.note
    }

    private func applyTimes() {
        store.updateSelectedTimes(start: Double(startText.replacingOccurrences(of: ",", with: ".")), end: Double(endText.replacingOccurrences(of: ",", with: ".")))
    }
}
