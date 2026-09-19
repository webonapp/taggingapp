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
    @Published var history = UndoRedoController()

    init() {
        project.labels = .demo
    }

    func newProject() {
        history.record(project)
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
        history.record(project)
        videoURL = url
        project.videoPath = url.path
        project.name = url.deletingPathExtension().lastPathComponent
        touch()
        status = "Video importato: \(url.lastPathComponent)"
    }

    func importSportscodePackage() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let imported = try SportscodePackageImporter.importPackage(at: url)
            history.record(project)
            videoURL = imported.videoURL
            project.videoPath = imported.videoURL?.path
            if let timeline = imported.timeline { project.timeline = timeline }
            project.name = url.deletingPathExtension().lastPathComponent
            touch()
            status = "Pacchetto Sportscode importato"
        } catch { status = "Errore import pacchetto: \(error.localizedDescription)" }
    }

    func importAdditionalAngle() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        history.record(project)
        project.angles.append(MediaAngle(name: "Angolo \(project.angles.count + 1)", path: url.path, isDefault: project.angles.isEmpty))
        touch()
        status = "Angolo aggiunto"
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
        history.record(project)
        project.timeline.rows.append(TimelineRow(name: name))
        touch()
    }

    func addInstance(rowID: UUID, start: Double, end: Double, labels: [TimelineLabel] = [], note: String = "") {
        guard let index = project.timeline.rows.firstIndex(where: { $0.id == rowID }) else { return }
        history.record(project)
        let number = project.timeline.rows[index].instances.count + 1
        project.timeline.rows[index].instances.append(TimelineInstance(startTime: start, endTime: end, labels: labels, note: note, instanceNumber: number))
        project.timeline.modifyCount += 1
        touch()
    }

    func addToPlaylist(instance: TimelineInstance, row: TimelineRow) {
        history.record(project)
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

    func importSlide() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .heic]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        history.record(project)
        let slide = PlaylistSlide(imagePath: url.path, title: url.deletingPathExtension().lastPathComponent)
        project.playlist.slides.append(slide)
        touch()
        status = "Slide aggiunta (3 secondi)"
    }

    func exportFirstSlide() {
        guard let slide = project.playlist.slides.first else { status = "Aggiungi prima una slide"; return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mpeg4Movie]
        panel.nameFieldStringValue = "\(slide.title).mp4"
        guard panel.runModal() == .OK, let destination = panel.url else { return }
        Task {
            do {
                try await SlideExporter.export(imageURL: URL(fileURLWithPath: slide.imagePath), duration: slide.duration, to: destination)
                status = "Slide esportata come video"
            } catch { status = "Errore slide: \(error.localizedDescription)" }
        }
    }

    func updateFirstSlideDuration(_ duration: Double) {
        guard !project.playlist.slides.isEmpty else { return }
        project.playlist.slides[0].duration = min(max(duration, 0.1), 60)
        touch()
    }

    func addPlaylistTitle(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        history.record(project)
        project.playlist.effects.append(PlaylistEffect(kind: .title, text: text))
        touch()
    }

    func exportCSV() {
        do { _ = try CSVExporter.export(project: project); status = "CSV esportato" }
        catch { status = "Errore CSV: \(error.localizedDescription)" }
    }

    func inspectCodeWindow() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let report = try CodeWindowCompatibility.inspect(url: url)
            status = "Code Window: \(report.notes)"
        } catch { status = "Errore Code Window: \(error.localizedDescription)" }
    }

    func exportPlaylistReferenceJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(project.name)-playlist.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try SportscodePlaylistExporter.exportReferenceJSON(project.playlist, projectName: project.name, to: url); status = "Playlist JSON esportata" }
        catch { status = "Errore playlist: \(error.localizedDescription)" }
    }

    func updateInstance(rowID: UUID, instanceID: UUID, startTime: Double? = nil, endTime: Double? = nil) {
        guard let rowIndex = project.timeline.rows.firstIndex(where: { $0.id == rowID }), let instanceIndex = project.timeline.rows[rowIndex].instances.firstIndex(where: { $0.id == instanceID }) else { return }
        history.record(project)
        if let startTime { project.timeline.rows[rowIndex].instances[instanceIndex].startTime = max(0, startTime) }
        if let endTime { project.timeline.rows[rowIndex].instances[instanceIndex].endTime = max(project.timeline.rows[rowIndex].instances[instanceIndex].startTime, endTime) }
        touch()
    }

    func updateInstanceLocation(rowID: UUID, instanceID: UUID, location: SpatialPoint) {
        guard let rowIndex = project.timeline.rows.firstIndex(where: { $0.id == rowID }), let instanceIndex = project.timeline.rows[rowIndex].instances.firstIndex(where: { $0.id == instanceID }) else { return }
        history.record(project)
        project.timeline.rows[rowIndex].instances[instanceIndex].location = location
        touch()
    }

    func undo() {
        if let value = history.undo(project, as: AnalysisProject.self) { project = value; videoURL = project.videoPath.map(URL.init(fileURLWithPath:)); status = "Annullato" }
    }

    func redo() {
        if let value = history.redo(project, as: AnalysisProject.self) { project = value; videoURL = project.videoPath.map(URL.init(fileURLWithPath:)); status = "Ripristinato" }
    }

    func saveProjectPackage() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(project.name).analysisproject"
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try ProjectPackageStore.save(project, to: url); status = "Pacchetto progetto salvato" }
        catch { status = "Errore pacchetto: \(error.localizedDescription)" }
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
