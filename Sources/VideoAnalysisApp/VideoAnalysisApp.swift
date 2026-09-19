import SwiftUI

@main
struct VideoAnalysisApp: App {
    @StateObject private var store = ProjectStore()

    var body: some Scene {
        WindowGroup("Video Analysis") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Nuovo progetto") { store.newProject() }
                    .keyboardShortcut("n", modifiers: [.command])
                Button("Apri progetto…") { store.openProject() }
                    .keyboardShortcut("o", modifiers: [.command])
                Button("Salva progetto") { store.saveProject() }
                    .keyboardShortcut("s", modifiers: [.command])
                Button("Annulla") { store.undo() }
                    .keyboardShortcut("z", modifiers: [.command])
                Button("Ripristina") { store.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
            }
        }
    }
}
