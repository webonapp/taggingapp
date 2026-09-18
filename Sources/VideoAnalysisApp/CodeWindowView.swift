import SwiftUI

struct CodeWindowView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    @Binding var selectedRowID: UUID?
    @State private var activeButtons: Set<UUID> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.project.codeWindow.name).font(.headline)
            Text("Premi i pulsanti o usa le hotkey").font(.caption).foregroundStyle(.secondary)
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(store.project.codeWindow.buttons) { button in
                        Button {
                            activate(button)
                        } label: {
                            VStack(spacing: 4) {
                                Text(button.name).font(.caption.bold())
                                Text(button.hotkey).font(.caption2.monospaced())
                            }
                            .frame(maxWidth: .infinity, minHeight: 62)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: button.colorHex))
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(.gray.opacity(0.08))
        .onKeyPress(keys: [.one, .two, .three, .four]) { press in
            let key: String
            switch press.key {
            case .one: key = "1"
            case .two: key = "2"
            case .three: key = "3"
            case .four: key = "4"
            default: return .ignored
            }
            guard let button = store.project.codeWindow.buttons.first(where: { $0.hotkey == key }) else { return .ignored }
            activate(button)
            return .handled
        }
    }

    private func activate(_ button: CodeButton) {
        let row: TimelineRow
        if let existing = store.project.timeline.rows.first(where: { $0.name == button.rowName }) {
            row = existing
        } else {
            store.addRow(name: button.rowName)
            guard let created = store.project.timeline.rows.last else { return }
            row = created
        }
        selectedRowID = row.id
        if button.mode == .instant {
            store.addInstance(rowID: row.id, start: max(0, currentTime - button.leadTime), end: currentTime + button.defaultDuration + button.lagTime, labels: button.automaticLabels)
        } else if activeButtons.contains(button.id) {
            activeButtons.remove(button.id)
            guard let index = store.project.timeline.rows.firstIndex(where: { $0.id == row.id }), let last = store.project.timeline.rows[index].instances.last else { return }
            store.project.timeline.rows[index].instances[indexOfLast(store.project.timeline.rows[index])].endTime = currentTime + button.lagTime
            _ = last
            store.touch()
        } else {
            activeButtons.insert(button.id)
            store.addInstance(rowID: row.id, start: max(0, currentTime - button.leadTime), end: currentTime)
        }
    }

    private func indexOfLast(_ row: TimelineRow) -> Int { max(0, row.instances.count - 1) }
}
