import SwiftUI

struct HeatmapView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var selectedRow: UUID?
    @State private var selectedInstance: UUID?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Heatmap").font(.title2.bold())
                Spacer()
                Picker("Riga", selection: $selectedRow) {
                    Text("Tutte").tag(Optional<UUID>.none)
                    ForEach(store.project.timeline.rows) { row in Text(row.name).tag(Optional(row.id)) }
                }
                .frame(width: 240)
                Picker("Evento", selection: $selectedInstance) {
                    Text("Nessun evento").tag(Optional<UUID>.none)
                    ForEach(selectedInstances) { instance in Text("\(instance.instanceNumber) · \(timecode(instance.startTime))").tag(Optional(instance.id)) }
                }
                .frame(width: 220)
            }
            GeometryReader { proxy in
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.28))
                    Rectangle().stroke(.white.opacity(0.8), lineWidth: 2).padding(12)
                    Path { path in
                        path.move(to: CGPoint(x: proxy.size.width / 2, y: 12)); path.addLine(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height - 12))
                        path.move(to: CGPoint(x: 12, y: proxy.size.height / 2)); path.addLine(to: CGPoint(x: proxy.size.width - 12, y: proxy.size.height / 2))
                    }.stroke(.white.opacity(0.6), lineWidth: 1)
                    ForEach(points) { point in
                    Circle().fill(Color.red.opacity(0.7)).frame(width: point.size, height: point.size).position(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
                    Text("Clicca sul campo per assegnare la posizione all'evento selezionato").font(.caption).foregroundStyle(.white.opacity(0.8)).padding(6).background(.black.opacity(0.35)).clipShape(Capsule())
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { value in
                    let location = value.location
                    guard let rowID = selectedRow, let instanceID = selectedInstance else { return }
                    let x = min(max(location.x / max(proxy.size.width, 1), 0), 1)
                    let y = min(max(location.y / max(proxy.size.height, 1), 0), 1)
                    store.updateInstanceLocation(rowID: rowID, instanceID: instanceID, location: SpatialPoint(x: x, y: y))
                })
                }
            }
        }
        .padding()
        .frame(minWidth: 650, minHeight: 440)
    }

    private var points: [HeatPoint] {
        store.project.timeline.rows.filter { selectedRow == nil || selectedRow == $0.id }.flatMap { row in
            row.instances.compactMap { instance in
                guard let location = instance.location else { return nil }
                return HeatPoint(x: min(max(location.x, 0), 1), y: min(max(location.y, 0), 1), size: CGFloat(min(max(instance.duration * 12, 8), 36)))
            }
        }
    }

    private var selectedInstances: [TimelineInstance] {
        store.project.timeline.rows.first(where: { $0.id == selectedRow })?.instances ?? []
    }

    private struct HeatPoint: Identifiable { let id = UUID(); let x: Double; let y: Double; let size: CGFloat }
    private func timecode(_ value: Double) -> String { String(format: "%02d:%02d", Int(value) / 60, Int(value) % 60) }
}
