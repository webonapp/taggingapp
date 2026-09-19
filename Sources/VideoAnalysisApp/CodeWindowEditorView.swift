import SwiftUI

struct CodeWindowEditorView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var selectedID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Pulsanti").font(.headline)
                    Spacer()
                    Button { store.addCodeButton(); selectedID = store.project.codeWindow.buttons.last?.id } label: { Image(systemName: "plus") }
                }
                List(store.project.codeWindow.buttons, selection: $selectedID) { button in
                    HStack {
                        Circle().fill(Color(hex: button.colorHex)).frame(width: 10, height: 10)
                        Text(button.name)
                        Spacer()
                        Text(button.hotkey).font(.caption.monospaced())
                    }
                    .tag(button.id)
                }
            }
            .padding()
            .frame(width: 280)
            Divider()
            if let selectedID, let index = store.project.codeWindow.buttons.firstIndex(where: { $0.id == selectedID }) {
                Form {
                    Text("Inspector").font(.headline)
                    TextField("Nome", text: binding(for: index, keyPath: \.name))
                    TextField("Riga associata", text: binding(for: index, keyPath: \.rowName))
                    TextField("Hotkey", text: binding(for: index, keyPath: \.hotkey))
                    Picker("Modalità", selection: binding(for: index, keyPath: \.mode)) {
                        Text("Toggle").tag(CodeButton.Mode.toggle)
                        Text("Istantaneo").tag(CodeButton.Mode.instant)
                    }
                    HStack {
                        Text("Colore")
                        TextField("#RRGGBB", text: binding(for: index, keyPath: \.colorHex))
                    }
                    HStack {
                        Text("Lead")
                        Slider(value: binding(for: index, keyPath: \.leadTime), in: 0...10)
                        Text("\(store.project.codeWindow.buttons[index].leadTime, specifier: "%.1f")s")
                    }
                    HStack {
                        Text("Lag")
                        Slider(value: binding(for: index, keyPath: \.lagTime), in: 0...10)
                        Text("\(store.project.codeWindow.buttons[index].lagTime, specifier: "%.1f")s")
                    }
                    Button("Elimina pulsante", role: .destructive) { store.deleteCodeButton(id: selectedID); self.selectedID = nil }
                    Spacer()
                }
                .padding()
            } else {
                ContentUnavailableView("Nessun pulsante selezionato", systemImage: "cursorarrow.click")
            }
        }
        .frame(minWidth: 760, minHeight: 500)
    }

    private func binding<Value>(for index: Int, keyPath: WritableKeyPath<CodeButton, Value>) -> Binding<Value> {
        Binding(get: { store.project.codeWindow.buttons[index][keyPath: keyPath] }, set: { value in store.project.codeWindow.buttons[index][keyPath: keyPath] = value; store.touch() })
    }
}
