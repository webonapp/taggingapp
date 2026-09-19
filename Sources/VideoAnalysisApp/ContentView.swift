import SwiftUI
import AVKit

struct ContentView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var selectedRowID: UUID?
    @State private var currentTime = 0.0
    @State private var duration = 1.0
    @State private var player = AVPlayer()
    @State private var timeObserver: Any?
    @State private var showFind = false
    @State private var showAnalysis = false
    @State private var showHeatmap = false
    @State private var selectedAngleID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    videoPane
                    Divider()
                    TimelineView(currentTime: $currentTime, duration: duration, selectedRowID: $selectedRowID)
                        .environmentObject(store)
                        .frame(minHeight: 260)
                }
                Divider()
                CodeWindowView(currentTime: $currentTime, selectedRowID: $selectedRowID)
                    .environmentObject(store)
                    .frame(width: 280)
            }
            HStack {
                Text(store.status).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(timecode(currentTime) + " / " + timecode(duration)).font(.caption.monospacedDigit())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .onAppear {
            loadVideoIfAvailable()
            installTimeObserver()
        }
        .onChange(of: store.videoURL) { _, _ in loadVideoIfAvailable() }
        .onChange(of: selectedAngleID) { _, _ in loadVideoIfAvailable() }
        .onDisappear {
            if let timeObserver { player.removeTimeObserver(timeObserver) }
            timeObserver = nil
        }
        .sheet(isPresented: $showFind) {
            FindWindowView(currentTime: $currentTime).environmentObject(store)
        }
        .sheet(isPresented: $showAnalysis) {
            AnalysisToolsView(currentTime: $currentTime).environmentObject(store)
        }
        .sheet(isPresented: $showHeatmap) {
            HeatmapView().environmentObject(store)
        }
    }

    private var toolbar: some View {
        HStack {
            Text(store.project.name).font(.headline)
            Spacer()
            Button("Importa video") { store.importVideo() }
            Button("Importa .SCVideo") { store.importSportscodePackage() }
            Button("Aggiungi angolo") { store.importAdditionalAngle() }
            if !store.project.angles.isEmpty {
                Picker("Angolo", selection: $selectedAngleID) {
                    Text("Video principale").tag(Optional<UUID>.none)
                    ForEach(store.project.angles) { angle in Text(angle.name).tag(Optional(angle.id)) }
                }
                .frame(width: 150)
            }
            Button("Importa SCTimeline") { store.importSportscodeTimeline() }
            Button("Importa playlist") { store.importSportscodePlaylist() }
            Button("Analizza CWcode2SC") { store.inspectCodeWindow() }
            Button("Esporta playlist JSON") { store.exportPlaylistReferenceJSON() }
            Button("Esporta XML") { store.exportTimelineXML() }
            Button("Esporta clip") { store.exportFirstClip() }
            Button("Importa slide") { store.importSlide() }
            Button("Esporta slide") { store.exportFirstSlide() }
            Button("Trova") { showFind = true }
                .keyboardShortcut("f", modifiers: [.command])
            Button("CSV") { store.exportCSV() }
            Button("Analisi") { showAnalysis = true }
            Button("Heatmap") { showHeatmap = true }
            if let slide = store.project.playlist.slides.first {
                Stepper("Slide \(slide.duration, specifier: "%.1f")s", value: Binding(get: { store.project.playlist.slides.first?.duration ?? 3 }, set: { store.updateFirstSlideDuration($0) }), in: 0.1...60, step: 0.1)
                    .help("Durata della prima slide della playlist")
            }
            Button("Salva pacchetto") { store.saveProjectPackage() }
            Button("Nuova riga") { store.addRow() }
            Button("Playlist \(store.project.playlist.clips.count)") { }
            Button("Salva") { store.saveProject() }
        }
        .padding(10)
    }

    private var videoPane: some View {
        ZStack {
            Color.black
            VideoPlayer(player: player)
                .onAppear { player.play() }
        }
        .frame(minHeight: 300)
        .overlay(alignment: .bottomLeading) {
            HStack {
                Button { player.seek(to: .zero) } label: { Image(systemName: "backward.end") }
                Button { player.rate == 0 ? player.play() : player.pause() } label: { Image(systemName: "playpause") }
                Slider(value: $currentTime, in: 0...max(duration, 0.01), onEditingChanged: { editing in
                    if !editing { player.seek(to: CMTime(seconds: currentTime, preferredTimescale: 600)) }
                })
            }
            .buttonStyle(.borderedProminent)
            .padding(10)
        }
    }

    private func loadVideoIfAvailable() {
        let angleURL = selectedAngleID.flatMap { id in store.project.angles.first(where: { $0.id == id }).map { URL(fileURLWithPath: $0.path) } }
        guard let url = angleURL ?? store.videoURL else { return }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        Task { @MainActor in
            let seconds = (try? await item.asset.load(.duration).seconds) ?? 1
            duration = max(seconds.isFinite ? seconds : 1, 1)
        }
    }

    private func installTimeObserver() {
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0 / 30.0, preferredTimescale: 600), queue: .main) { time in
            currentTime = max(0, time.seconds)
        }
    }

    private func timecode(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }
}
