import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class ProjectStore: ObservableObject {
    @Published var project = AnalysisProject()
    @Published var projectURL: URL?
    @Published var videoURL: URL?
    @Published var status = "Pronto"

    init() {
        project.labels = .demo
    }

    func newProject() {
        project = AnalysisProject()
        project.labels = .demo
        projectURL = nil
        videoURL = nil
        status = "Nuovo progetto"
    }

    func importVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        videoURL = url
        project.videoPath = url.path
        project.name = url.deletingPathExtension().lastPathComponent
        touch()
        status = "Video importato: \(url.lastPathComponent)"
    }

    func openProject() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            project = try JSONDecoder.projectDecoder.decode(AnalysisProject.self, from: Data(contentsOf: url))
            projectURL = url
            videoURL = project.videoPath.map(URL.init(fileURLWithPath:))
            status = "Progetto aperto"
        } catch {
            status = "Errore apertura: \(error.localizedDescription)"
        }
    }

    func saveProject() {
        let url: URL
        if let projectURL { url = projectURL }
        else {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "\(project.name).analysisproject.json"
            guard panel.runModal() == .OK, let selected = panel.url else { return }
            url = selected
            projectURL = selected
        }
        do {
            project.modifiedAt = Date()
            let data = try JSONEncoder.projectEncoder.encode(project)
            try data.write(to: url, options: .atomic)
            status = "Salvato"
        } catch {
            status = "Errore salvataggio: \(error.localizedDescription)"
        }
    }

    func addRow(name: String = "Nuova riga") {
        project.timeline.rows.append(TimelineRow(name: name))
        touch()
    }

    func addInstance(rowID: UUID, start: Double, end: Double, labels: [TimelineLabel] = [], note: String = "") {
        guard let index = project.timeline.rows.firstIndex(where: { $0.id == rowID }) else { return }
        let number = project.timeline.rows[index].instances.count + 1
        project.timeline.rows[index].instances.append(TimelineInstance(startTime: start, endTime: end, labels: labels, note: note, instanceNumber: number))
        project.timeline.modifyCount += 1
        touch()
    }

    func addToPlaylist(instance: TimelineInstance, row: TimelineRow) {
        let clip = PlaylistClip(sourceRowID: row.id, sourceInstanceID: instance.id, startTime: instance.startTime, endTime: instance.endTime, title: "\(row.name) #\(instance.instanceNumber)", note: instance.note, labels: instance.labels)
        project.playlist.clips.append(clip)
        touch()
        status = "Clip aggiunta alla playlist"
    }

    func importSportscodeTimeline() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            project.timeline = try SportscodeInterop.importTimeline(from: url)
            touch()
            status = "Timeline Sportscode importata"
        } catch { status = "Errore import timeline: \(error.localizedDescription)" }
    }

    func importSportscodePlaylist() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            project.playlist = try SportscodeInterop.importPlaylist(from: url)
            touch()
            status = "Playlist Sportscode importata"
        } catch { status = "Errore import playlist: \(error.localizedDescription)" }
    }

    func exportTimelineXML() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.xml]
        panel.nameFieldStringValue = "\(project.name).xml"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try SportscodeInterop.exportXML(project.timeline, to: url)
            status = "Timeline XML esportata"
        } catch { status = "Errore export XML: \(error.localizedDescription)" }
    }

    func exportFirstClip() {
        guard let videoURL, let clip = project.playlist.clips.first else {
            status = "Aggiungi prima un clip alla playlist"
            return
        }
        Task {
            do {
                _ = try await VideoExporter.shared.exportClip(videoURL: videoURL, startTime: max(0, clip.startTime - clip.preRoll), endTime: clip.endTime + clip.postRoll, suggestedName: clip.title)
                status = "Clip esportato"
            } catch { status = "Errore export clip: \(error.localizedDescription)" }
        }
    }

    func touch() {
        project.modifiedAt = Date()
        project.timeline.modifyCount += 1
    }
}

extension JSONEncoder {
    static let projectEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let projectDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
