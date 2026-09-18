import SwiftUI
import AVKit

struct ContentView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var selectedRowID: UUID?
    @State private var currentTime = 0.0
    @State private var duration = 1.0
    @State private var player = AVPlayer()

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
        .onAppear { loadVideoIfAvailable() }
        .onChange(of: store.videoURL) { _, _ in loadVideoIfAvailable() }
    }

    private var toolbar: some View {
        HStack {
            Text(store.project.name).font(.headline)
            Spacer()
            Button("Importa video") { store.importVideo() }
            Button("Importa SCTimeline") { store.importSportscodeTimeline() }
            Button("Importa playlist") { store.importSportscodePlaylist() }
            Button("Esporta XML") { store.exportTimelineXML() }
            Button("Esporta clip") { store.exportFirstClip() }
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
        guard let url = store.videoURL else { return }
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        Task { @MainActor in
            let seconds = (try? await item.asset.load(.duration).seconds) ?? 1
            duration = max(seconds.isFinite ? seconds : 1, 1)
        }
    }

    private func timecode(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, (total / 60) % 60, total % 60)
    }
}
