import Foundation

struct AnalysisProject: Codable, Identifiable {
    var id = UUID()
    var name = "Nuovo progetto"
    var videoPath: String?
    var timeline = TimelineModel()
    var labels = LabelLibrary()
    var playlist = PlaylistModel()
    var codeWindow = CodeWindowModel.defaultWindow()
    var angles: [MediaAngle] = []
    var createdAt = Date()
    var modifiedAt = Date()

    enum CodingKeys: String, CodingKey { case id, name, videoPath, timeline, labels, playlist, codeWindow, angles, createdAt, modifiedAt }

    init(id: UUID = UUID(), name: String = "Nuovo progetto", videoPath: String? = nil, timeline: TimelineModel = TimelineModel(), labels: LabelLibrary = LabelLibrary(), playlist: PlaylistModel = PlaylistModel(), codeWindow: CodeWindowModel = CodeWindowModel.defaultWindow(), angles: [MediaAngle] = [], createdAt: Date = Date(), modifiedAt: Date = Date()) {
        self.id = id; self.name = name; self.videoPath = videoPath; self.timeline = timeline; self.labels = labels; self.playlist = playlist; self.codeWindow = codeWindow; self.angles = angles; self.createdAt = createdAt; self.modifiedAt = modifiedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Nuovo progetto"
        videoPath = try c.decodeIfPresent(String.self, forKey: .videoPath)
        timeline = try c.decodeIfPresent(TimelineModel.self, forKey: .timeline) ?? TimelineModel()
        labels = try c.decodeIfPresent(LabelLibrary.self, forKey: .labels) ?? LabelLibrary()
        playlist = try c.decodeIfPresent(PlaylistModel.self, forKey: .playlist) ?? PlaylistModel()
        codeWindow = try c.decodeIfPresent(CodeWindowModel.self, forKey: .codeWindow) ?? CodeWindowModel.defaultWindow()
        angles = try c.decodeIfPresent([MediaAngle].self, forKey: .angles) ?? []
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? Date()
    }
}

struct MediaAngle: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var path: String
    var isDefault = false
    var isMuted = false
}

struct SpatialPoint: Codable, Hashable {
    var x: Double
    var y: Double
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
    var location: SpatialPoint?

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
    var links: [CodeWindowLink] = []
    var categories: [CodeWindowCategory] = []
    var globalLeadTime: Double = 0
    var globalLagTime: Double = 0
    var sourceFormat: String? = nil
    var sourceArchiveData: Data? = nil

    enum CodingKeys: String, CodingKey {
        case name, buttons, links, categories, globalLeadTime, globalLagTime, sourceFormat, sourceArchiveData
    }

    init(name: String, buttons: [CodeButton], links: [CodeWindowLink] = [], categories: [CodeWindowCategory] = [], globalLeadTime: Double = 0, globalLagTime: Double = 0, sourceFormat: String? = nil, sourceArchiveData: Data? = nil) {
        self.name = name
        self.buttons = buttons
        self.links = links
        self.categories = categories
        self.globalLeadTime = globalLeadTime
        self.globalLagTime = globalLagTime
        self.sourceFormat = sourceFormat
        self.sourceArchiveData = sourceArchiveData
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Code Window"
        buttons = try c.decodeIfPresent([CodeButton].self, forKey: .buttons) ?? []
        links = try c.decodeIfPresent([CodeWindowLink].self, forKey: .links) ?? []
        categories = try c.decodeIfPresent([CodeWindowCategory].self, forKey: .categories) ?? []
        globalLeadTime = try c.decodeIfPresent(Double.self, forKey: .globalLeadTime) ?? 0
        globalLagTime = try c.decodeIfPresent(Double.self, forKey: .globalLagTime) ?? 0
        sourceFormat = try c.decodeIfPresent(String.self, forKey: .sourceFormat)
        sourceArchiveData = try c.decodeIfPresent(Data.self, forKey: .sourceArchiveData)
    }

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
    enum Mode: String, Codable { case toggle, instant, inOut, outOnly }
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
    var captureMode: String? = nil
    var preSeconds: Double? = nil
    var secondaryName: String = ""
    var sportscodeType: Int? = nil
    var actionType: Int? = nil
    var showOutput: Bool = false
    var populateTimeline: Bool = false
    var script: String? = nil
    var sourceIdentifier: String? = nil
}

struct CodeWindowLink: Codable, Identifiable {
    var id = UUID()
    var fromButtonID: UUID
    var toButtonID: UUID
    var type: Int = 1
    var label: String? = nil
    var exclusive: Bool { type == 0 }
}

struct CodeWindowCategory: Codable, Identifiable {
    var id = UUID()
    var name: String
    var buttonIDs: [UUID] = []
}

struct PlaylistModel: Codable {
    var name = "Nuova playlist"
    var groups: [PlaylistGroup] = []
    var clips: [PlaylistClip] = []
    var slides: [PlaylistSlide] = []
    var effects: [PlaylistEffect] = []

    init(name: String = "Nuova playlist", groups: [PlaylistGroup] = [], clips: [PlaylistClip] = [], slides: [PlaylistSlide] = [], effects: [PlaylistEffect] = []) {
        self.name = name
        self.groups = groups
        self.clips = clips
        self.slides = slides
        self.effects = effects
    }

    enum CodingKeys: String, CodingKey { case name, groups, clips, slides, effects }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Nuova playlist"
        groups = try container.decodeIfPresent([PlaylistGroup].self, forKey: .groups) ?? []
        clips = try container.decodeIfPresent([PlaylistClip].self, forKey: .clips) ?? []
        slides = try container.decodeIfPresent([PlaylistSlide].self, forKey: .slides) ?? []
        effects = try container.decodeIfPresent([PlaylistEffect].self, forKey: .effects) ?? []
    }
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

struct PlaylistSlide: Codable, Identifiable {
    var id = UUID()
    var imagePath: String
    var title: String
    var duration: Double = 3
    var note = ""
    var groupID: UUID?
}

struct PlaylistEffect: Codable, Identifiable {
    enum Kind: String, Codable { case title, textOverlay, line, rectangle, circle }
    var id = UUID()
    var kind: Kind
    var text: String = ""
    var colorHex: String = "#FFFFFF"
    var startTime: Double = 0
    var endTime: Double = 3
    var x: Double = 0.05
    var y: Double = 0.05
    var width: Double = 0.9
    var height: Double = 0.12
    var fontSize: Double = 32
}
