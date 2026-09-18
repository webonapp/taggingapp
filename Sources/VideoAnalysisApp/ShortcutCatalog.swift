import Foundation

struct ShortcutDefinition: Identifiable, Hashable {
    enum Group: String, CaseIterable { case macOS, sportscode, playback, instancePlayer, timeline, playlist, sorter, codeWindow }
    let id = UUID()
    let group: Group
    let action: String
    let shortcut: String
}

enum ShortcutCatalog {
    static let all: [ShortcutDefinition] = [
        s(.macOS, "Salva", "⌘S"), s(.macOS, "Salva con nome", "⌥⇧⌘S"), s(.macOS, "Apri", "⌘O"), s(.macOS, "Esci", "⌘Q"), s(.macOS, "Chiudi finestra", "⌘W"), s(.macOS, "Chiudi tutte le finestre", "⌥⌘W"), s(.macOS, "Annulla", "⌘Z"), s(.macOS, "Copia", "⌘C"), s(.macOS, "Incolla", "⌘V"), s(.macOS, "Seleziona tutto", "⌘A"), s(.macOS, "Fullscreen", "⌃⌘F"), s(.macOS, "Mostra/nascondi toolbar", "⌥⌘T"),
        s(.sportscode, "Nuovo Organizer", "⌘N"), s(.sportscode, "Importa video", "⌃⌘V"), s(.sportscode, "Importa XML", "⌃⇧X"), s(.sportscode, "Esporta video", "⌃⌥V"), s(.sportscode, "Esporta XML", "⌃⌥X"), s(.sportscode, "Modifica video", "⌃⇧V"), s(.sportscode, "Finestra Trova", "⌘F"), s(.sportscode, "Selezione multipla", "⌘-clic"), s(.sportscode, "Invia a Organizer", "⌥⌘V"), s(.sportscode, "Invia a Sorter", "⇧⌘V"),
        s(.playback, "Play/Pausa", "Spazio"), s(.playback, "Avanti continuo", "."), s(.playback, "Indietro continuo", ","), s(.playback, "Presenta", "⌘M"), s(.playback, "Presenta dall'inizio", "⇧⌘M"), s(.playback, "Prossima istanza", "Tab"), s(.playback, "Istanza precedente", "⇧Tab"), s(.playback, "Reset zoom", "⌘0"), s(.playback, "Testo istanza", "⇧⌘T"), s(.playback, "Esci fullscreen", "Esc"),
        s(.instancePlayer, "Modifica istanza", "⌃E"), s(.instancePlayer, "Segna inizio", "⌃I"), s(.instancePlayer, "Segna fine", "⌃O"), s(.instancePlayer, "Estendi inizio", "⇧⌃I"), s(.instancePlayer, "Estendi fine", "⇧⌃O"), s(.instancePlayer, "Ritaglia", "⌃T"), s(.instancePlayer, "Impila player", "⌘Y"),
        s(.timeline, "Modifica label", "⌘E"), s(.timeline, "Modifica note", "⌃N"), s(.timeline, "Regolazioni istanza", "⌃A"), s(.timeline, "Allinea tutto", "⌥Z"), s(.timeline, "Allinea a destra", "⌥X"), s(.timeline, "Codifica fullscreen", "⇧⌘F"), s(.timeline, "Nota e clip successiva", "⌃Tab"), s(.timeline, "Istanza cronologica successiva", "Tab"), s(.timeline, "Crea istanza", "⇧⌥⌘-drag"), s(.timeline, "Copia istanza tra righe", "⌥-drag"),
        s(.playlist, "Avvia/arresta registrazione", "⌃S"), s(.playlist, "Pausa registrazione", "⌃P"), s(.playlist, "Effetti", "⌃E / ⌘E"), s(.playlist, "Disegno linea", "⌃B / ⌘B"), s(.playlist, "Casella testo", "⌘T"),
        s(.sorter, "Modifica cella", "Invio"), s(.sorter, "Cella successiva", "Tab"), s(.sorter, "Cella precedente", "⇧Tab"), s(.sorter, "Cella sotto", "⌃Tab"), s(.sorter, "Cella sopra", "⇧⌃Tab"),
        s(.codeWindow, "Annulla codici attivi", "Esc"), s(.codeWindow, "Chiudi codici attivi", "Tab"), s(.codeWindow, "Nota live", "⌃="), s(.codeWindow, "Annulla pulsanti aperti", "⌃Esc"), s(.codeWindow, "Modalità successiva", "⌥↓"), s(.codeWindow, "Modalità precedente", "⌥↑"), s(.codeWindow, "Link attivazione", "⌃⌥-drag"), s(.codeWindow, "Link disattivazione", "⌃⇧-drag"), s(.codeWindow, "Link esclusivo", "⌃-drag")
    ]

    private static func s(_ group: ShortcutDefinition.Group, _ action: String, _ shortcut: String) -> ShortcutDefinition {
        ShortcutDefinition(group: group, action: action, shortcut: shortcut)
    }
}
