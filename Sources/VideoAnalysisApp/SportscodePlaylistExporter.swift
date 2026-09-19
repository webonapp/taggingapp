import Foundation

enum SportscodePlaylistExporter {
    static func exportReferenceJSON(_ playlist: PlaylistModel, projectName: String, to url: URL) throws {
        let clips: [[String: Any]] = playlist.clips.map { clip in
            ["id": clip.id.uuidString, "startTime": clip.startTime, "endTime": clip.endTime, "startTimeOffset": clip.preRoll, "timelineName": projectName, "description": clip.note, "videoId": "native-project"]
        }
        let slides: [[String: Any]] = playlist.slides.map { slide in
            ["id": slide.id.uuidString, "type": "slide", "duration": slide.duration, "title": slide.title, "imagePath": slide.imagePath]
        }
        let object: [String: Any] = ["version": "native-1.0", "playlist": ["clips": clips, "slides": slides, "groups": playlist.groups.map { ["id": $0.id.uuidString, "name": $0.name, "color": $0.colorHex, "clipIds": $0.clipIDs.map(\.uuidString)] }]]
        guard JSONSerialization.isValidJSONObject(object) else { throw ExportError.invalid }
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url, options: .atomic)
    }

    enum ExportError: LocalizedError { case invalid; var errorDescription: String? { "Playlist non esportabile" } }
}
