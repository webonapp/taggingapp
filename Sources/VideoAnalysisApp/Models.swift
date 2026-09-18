import Foundation

struct AnalysisProject: Codable, Identifiable {
    var id = UUID()
    var name = "Nuovo progetto"
    var videoPath: String?
    var timeline = TimelineModel()
    var labels = LabelLibrary()
    var playlist = PlaylistModel()
    var codeWindow = CodeWindowModel.defaultWindow()
    var createdAt = Date()
    var modifiedAt = Date()
}

struct TimelineModel: Codable {
    var currentPlaybackTime: Double = 0
    var rows: [TimelineRow] = []
    var modifyCount = 0
}

struct TimelineRow: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var colorHex: String = "#FFFFFF"
    var isVisible = true
    var isLocked = false
    var instances: [TimelineInstance] = []

    init(name: String, colorHex: String = "#FFFFFF") {
        self.name = name
        self.colorHex = colorHex
    }
}

struct TimelineInstance: Codable, Identifiable, Hashable {
    var id = UUID()
    var startTime: Double
    var endTime: Double
    var labels: [TimelineLabel] = []
    var note = ""
    var isFlagged = false
    var instanceNumber = 1

    var duration: Double { max(0, endTime - startTime) }
}

struct TimelineLabel: Codable, Hashable {
    var name: String
    var group: String = ""
}

struct LabelLibrary: Codable {
    var groups: [LabelGroup] = []

    static var demo: LabelLibrary {
        LabelLibrary(groups: [
            LabelGroup(name: "01. Rimessa dal fondo", labels: ["Corto", "Lungo", "Schema"]),
            LabelGroup(name: "02. Transizioni", labels: ["Da recupero alto", "Da recupero basso", "Riaggressione"]),
            LabelGroup(name: "03. Occasioni", labels: ["Occasione creata", "Occasione subita"]),
            LabelGroup(name: "07. Player", labels: ["FAGIOLI", "DODO", "GONZALEZ"])
        ])
    }
}

struct LabelGroup: Codable, Identifiable {
    var id = UUID()
    var name: String
    var labels: [String]
}

struct CodeWindowModel: Codable {
    var name: String
    var buttons: [CodeButton]

    static func defaultWindow() -> CodeWindowModel {
        CodeWindowModel(name: "Code Window", buttons: [
            CodeButton(name: "Inizio gioco", rowName: "Inizio gioco", colorHex: "#6E48AA", hotkey: "1", mode: .toggle),
            CodeButton(name: "Pressing", rowName: "Pressing", colorHex: "#9F1503", hotkey: "2", mode: .toggle),
            CodeButton(name: "Palle laterali", rowName: "Palle laterali", colorHex: "#107D0B", hotkey: "3", mode: .toggle),
            CodeButton(name: "Azione di rilievo", rowName: "Azione di rilievo", colorHex: "#D88B00", hotkey: "4", mode: .instant)
        ])
    }
}

struct CodeButton: Codable, Identifiable {
    enum Mode: String, Codable { case toggle, instant }
    var id = UUID()
    var name: String
    var rowName: String
    var colorHex: String
    var hotkey: String
    var mode: Mode
    var leadTime: Double = 0
    var lagTime: Double = 0
    var defaultDuration: Double = 2
    var automaticLabels: [TimelineLabel] = []
}

struct PlaylistModel: Codable {
    var name = "Nuova playlist"
    var groups: [PlaylistGroup] = []
    var clips: [PlaylistClip] = []
}

struct PlaylistGroup: Codable, Identifiable {
    var id = UUID()
    var name: String
    var colorHex = "#E9E9E9"
    var clipIDs: [UUID] = []
}

struct PlaylistClip: Codable, Identifiable {
    var id = UUID()
    var sourceRowID: UUID?
    var sourceInstanceID: UUID?
    var startTime: Double
    var endTime: Double
    var preRoll: Double = 0
    var postRoll: Double = 0
    var title: String
    var note = ""
    var labels: [TimelineLabel] = []
    var groupID: UUID?
}
