import SwiftUI

struct AnalysisToolsView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Analisi", selection: $tab) {
                Text("Database").tag(0)
                Text("Sorter").tag(1)
                Text("Matrix").tag(2)
                Text("Report").tag(3)
                Text("Playlist").tag(4)
                Text("Output").tag(5)
            }
            .pickerStyle(.segmented)
            .padding()
            Group {
                switch tab {
                case 0: DatabaseTableView(currentTime: $currentTime)
                case 1: SorterTableView(currentTime: $currentTime)
                case 2: MatrixTableView()
                case 4: PlaylistSorterView(currentTime: $currentTime)
                case 5: OutputWindowView().environmentObject(store)
                default: ReportTableView()
                }
            }
        }
        .frame(minWidth: 900, minHeight: 520)
    }
}

struct PlaylistSorterView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    @State private var newTitle = ""

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(store.project.playlist.name).font(.headline)
                Spacer()
                Text("\(store.project.playlist.clips.count) clip · \(store.project.playlist.slides.count) slide").foregroundStyle(.secondary)
            }
            HStack {
                TextField("Titolo / overlay", text: $newTitle)
                Button("Aggiungi titolo") { store.addPlaylistTitle(newTitle); newTitle = "" }
                Text("Effetti: \(store.project.playlist.effects.count)").foregroundStyle(.secondary)
            }
            List {
                ForEach(Array(store.project.playlist.clips.enumerated()), id: \.element.id) { index, clip in
                    HStack {
                        Text("\(index + 1)").foregroundStyle(.secondary).frame(width: 30)
                        Button { currentTime = clip.startTime } label: { Image(systemName: "play.fill") }.buttonStyle(.plain)
                        Text(clip.title).frame(width: 280, alignment: .leading)
                        Text(timecode(clip.startTime)).monospacedDigit()
                        Text("–")
                        Text(timecode(clip.endTime)).monospacedDigit()
                        Spacer()
                        Text(clip.labels.map(\.name).joined(separator: ", ")).foregroundStyle(.secondary)
                    }
                }
                .onMove { offsets, destination in
                    store.project.playlist.clips.move(fromOffsets: offsets, toOffset: destination)
                    store.touch()
                }
                ForEach(store.project.playlist.slides) { slide in
                    HStack {
                        Image(systemName: "photo")
                        Text(slide.title)
                        Spacer()
                        Text("\(slide.duration, specifier: "%.1f") s").monospacedDigit()
                    }
                }
            }
        }
        .padding()
    }
}

struct DatabaseTableView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    var body: some View {
        Table(AnalysisEngine.database(from: store.project)) {
            TableColumn("Riga", value: \.rowName)
            TableColumn("Inizio") { entry in Button(timecode(entry.startTime)) { currentTime = entry.startTime }.buttonStyle(.plain) }
            TableColumn("Fine") { entry in Text(timecode(entry.endTime)) }
            TableColumn("Label") { entry in Text(entry.labels.map(\.name).joined(separator: ", ")) }
            TableColumn("Nota") { entry in Text(entry.note) }
        }
        .padding()
    }
}

struct SorterTableView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    var body: some View {
        List(AnalysisEngine.database(from: store.project)) { entry in
            HStack {
                Button { currentTime = entry.startTime } label: { Image(systemName: "play.fill") }.buttonStyle(.plain)
                Text(entry.rowName).frame(width: 240, alignment: .leading)
                Text(timecode(entry.startTime)).monospacedDigit()
                Text(entry.labels.map(\.name).joined(separator: ", ")).foregroundStyle(.secondary)
                Spacer()
                if entry.flagged { Image(systemName: "flag.fill") }
            }
        }
        .padding()
    }
}

struct MatrixTableView: View {
    @EnvironmentObject private var store: ProjectStore
    var body: some View {
        let cells = AnalysisEngine.matrix(from: store.project)
        let rows = Array(Set(cells.map(\.rowLabel))).sorted()
        let columns = Array(Set(cells.map(\.columnLabel))).sorted()
        return ScrollView([.horizontal, .vertical]) {
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow { Text("Riga").bold(); ForEach(columns, id: \.self) { Text($0).bold().frame(width: 120) } }
                ForEach(rows, id: \.self) { row in
                    GridRow {
                        Text(row).frame(width: 240, alignment: .leading)
                        ForEach(columns, id: \.self) { column in
                            Text(String(cells.first(where: { $0.rowLabel == row && $0.columnLabel == column })?.count ?? 0))
                                .frame(width: 120, height: 32)
                                .background(.purple.opacity(0.1))
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ReportTableView: View {
    @EnvironmentObject private var store: ProjectStore
    var body: some View {
        let report = AnalysisEngine.report(from: store.project)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                metric("Istanze", String(report.totalInstances))
                metric("Durata", timecode(report.totalDuration))
                metric("Flag", String(report.flaggedInstances))
            }
            Divider()
            Text("Eventi per riga").font(.headline)
            ForEach(Array(report.rowCounts.enumerated()), id: \.offset) { _, item in Text("\(item.name): \(item.count)") }
            Text("Label più utilizzate").font(.headline).padding(.top)
            ForEach(Array(report.labelCounts.enumerated()), id: \.offset) { _, item in Text("\(item.name): \(item.count)") }
            Spacer()
        }
        .padding()
    }

    private func metric(_ title: String, _ value: String) -> some View { VStack { Text(value).font(.title2.bold()); Text(title).font(.caption).foregroundStyle(.secondary) }.frame(width: 150) }
}

private func timecode(_ value: Double) -> String { String(format: "%02d:%02d:%05.2f", Int(value) / 60, Int(value) % 60, value.truncatingRemainder(dividingBy: 60)) }
