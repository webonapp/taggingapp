import Foundation

enum ProjectPackageStore {
    static let packageExtension = "analysisproject"

    static func save(_ project: AnalysisProject, to directory: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        for folder in ["Media", "Timelines", "CodeWindows", "Playlists", "Labels", "Backups"] {
            try fm.createDirectory(at: directory.appendingPathComponent(folder), withIntermediateDirectories: true)
        }
        let projectData = try JSONEncoder.projectEncoder.encode(project)
        try projectData.write(to: directory.appendingPathComponent("project.json"), options: .atomic)
        let timelineData = try JSONEncoder.projectEncoder.encode(project.timeline)
        try timelineData.write(to: directory.appendingPathComponent("Timelines/timeline.json"), options: .atomic)
        let codeData = try JSONEncoder.projectEncoder.encode(project.codeWindow)
        try codeData.write(to: directory.appendingPathComponent("CodeWindows/default.codewindow.json"), options: .atomic)
        let playlistData = try JSONEncoder.projectEncoder.encode(project.playlist)
        try playlistData.write(to: directory.appendingPathComponent("Playlists/playlist.json"), options: .atomic)
        let labelsData = try JSONEncoder.projectEncoder.encode(project.labels)
        try labelsData.write(to: directory.appendingPathComponent("Labels/labels.json"), options: .atomic)
    }

    static func load(from directory: URL) throws -> AnalysisProject {
        let data = try Data(contentsOf: directory.appendingPathComponent("project.json"))
        return try JSONDecoder.projectDecoder.decode(AnalysisProject.self, from: data)
    }
}
