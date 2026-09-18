import Foundation

struct SportscodeTimelineFile: Codable {
    var currentPlaybackTime: Double?
    var timeline: SportscodeTimelinePayload
}

struct SportscodeTimelinePayload: Codable {
    var currentModifyCount: Int?
    var packagePath: String?
    var uniqueId: String?
    var labels: [TimelineLabel]?
    var rows: [SportscodeRow]
}

struct SportscodeRow: Codable {
    var instances: [SportscodeInstance]
    var name: String
    var uniqueId: String?
    var rowNum: Int?
    var modifyCount: Int?
    var color: String?
}

struct SportscodeInstance: Codable {
    var sharing: Bool?
    var startTime: Double
    var labels: [TimelineLabel]?
    var instanceNum: Int?
    var endTime: Double
    var modifyCount: Int?
    var uniqueId: String?
    var notes: String?
}

struct SportscodePlaylistFile: Codable {
    var version: String?
    var playlist: SportscodePlaylistPayload
}

struct SportscodePlaylistPayload: Codable {
    var clips: [SportscodePlaylistClip]?
    var groups: [SportscodePlaylistGroup]?
}

struct SportscodePlaylistClip: Codable {
    var id: String?
    var videoId: String?
    var startTime: Double
    var endTime: Double
    var startTimeOffset: Double?
    var timelineName: String?
    var description: String?
    var moment: SportscodeMoment?
}

struct SportscodeMoment: Codable {
    var startTime: Double
    var endTime: Double
    var note: String?
    var tags: [TimelineLabel]?
}

struct SportscodePlaylistGroup: Codable {
    var id: String?
    var name: String
    var color: String?
    var clipIds: [String]?
}

enum SportscodeInterop {
    static func importTimeline(from url: URL) throws -> TimelineModel {
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder.projectDecoder.decode(SportscodeTimelineFile.self, from: data)
        var model = TimelineModel(currentPlaybackTime: file.currentPlaybackTime ?? 0, rows: [], modifyCount: file.timeline.currentModifyCount ?? 0)
        for sourceRow in file.timeline.rows {
            var row = TimelineRow(name: sourceRow.name, colorHex: sourceRow.color ?? "#FFFFFF")
            row.instances = sourceRow.instances.map {
                TimelineInstance(startTime: $0.startTime, endTime: $0.endTime, labels: $0.labels ?? [], note: $0.notes ?? "", instanceNumber: $0.instanceNum ?? 1)
            }
            model.rows.append(row)
        }
        return model
    }

    static func importPlaylist(from url: URL) throws -> PlaylistModel {
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder.projectDecoder.decode(SportscodePlaylistFile.self, from: data)
        var playlist = PlaylistModel()
        var idMap: [String: UUID] = [:]
        for sourceGroup in file.playlist.groups ?? [] {
            let group = PlaylistGroup(name: sourceGroup.name, colorHex: sourceGroup.color ?? "#E9E9E9")
            playlist.groups.append(group)
            if let id = sourceGroup.id { idMap[id] = group.id }
        }
        playlist.clips = (file.playlist.clips ?? []).map {
            PlaylistClip(startTime: $0.startTime, endTime: $0.endTime, preRoll: $0.startTimeOffset ?? 0, title: $0.timelineName ?? "Clip", note: $0.description ?? "")
        }
        return playlist
    }

    static func exportXML(_ timeline: TimelineModel, to url: URL) throws {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<sportscodeTimeline version=\"1.0\">\n"
        for row in timeline.rows {
            xml += "  <row name=\"\(escape(row.name))\" color=\"\(row.colorHex)\">\n"
            for instance in row.instances {
                xml += "    <instance start=\"\(instance.startTime)\" end=\"\(instance.endTime)\" number=\"\(instance.instanceNumber)\">\n"
                if !instance.note.isEmpty { xml += "      <note>\(escape(instance.note))</note>\n" }
                for label in instance.labels {
                    xml += "      <label group=\"\(escape(label.group))\">\(escape(label.name))</label>\n"
                }
                xml += "    </instance>\n"
            }
            xml += "  </row>\n"
        }
        xml += "</sportscodeTimeline>\n"
        try Data(xml.utf8).write(to: url, options: .atomic)
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
