import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var store: ProjectStore
    @Binding var currentTime: Double
    let duration: Double
    @Binding var selectedRowID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Timeline").font(.headline)
                Spacer()
                Button { store.addRow() } label: { Label("Riga", systemImage: "plus") }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 1) {
                    ruler
                    ForEach(store.project.timeline.rows) { row in
                        rowView(row)
                    }
                    if store.project.timeline.rows.isEmpty {
                        Text("Aggiungi una riga o usa la Code Window per iniziare a codificare.")
                            .foregroundStyle(.secondary)
                            .padding(20)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onDeleteCommand {
            guard let rowID = store.selectedRowID, let instanceID = store.selectedInstanceIDs.first else { return }
            store.deleteInstance(rowID: rowID, instanceID: instanceID)
            store.clearSelection()
        }
    }

    private var ruler: some View {
        HStack(spacing: 0) {
            Text("Righe").frame(width: 190, alignment: .leading).padding(.leading, 10)
            ZStack(alignment: .leading) {
                Rectangle().fill(.secondary.opacity(0.2)).frame(height: 1)
                Text("00:00:00").font(.caption.monospacedDigit()).offset(x: 4)
            }
            .frame(width: 900, height: 28, alignment: .leading)
        }
        .background(.quaternary.opacity(0.5))
    }

    private func rowView(_ row: TimelineRow) -> some View {
        HStack(spacing: 0) {
            Text(row.name)
                .font(.caption)
                .lineLimit(2)
                .frame(width: 190, height: 48, alignment: .leading)
                .padding(.leading, 10)
                .background(Color(hex: row.colorHex).opacity(0.22))
                .contentShape(Rectangle())
                .onTapGesture { selectedRowID = row.id }
            ZStack(alignment: .leading) {
                Rectangle().fill(.white.opacity(0.04))
                ForEach(row.instances) { instance in
                    instanceView(instance, row: row)
                        .offset(x: CGFloat(instance.startTime / max(duration, 1)) * 900)
                }
                Rectangle()
                    .fill(.red)
                    .frame(width: 2, height: 48)
                    .offset(x: CGFloat(currentTime / max(duration, 1)) * 900)
            }
            .frame(width: 900, height: 48)
            .border(.gray.opacity(0.25))
        }
    }

    private func instanceView(_ instance: TimelineInstance, row: TimelineRow) -> some View {
        let width = max(CGFloat(instance.duration / max(duration, 1)) * 900, 8)
        return ZStack(alignment: .leading) {
            HStack(spacing: 3) {
                Text(instance.labels.first?.name ?? "#\(instance.instanceNumber)")
                    .font(.caption2)
                    .lineLimit(1)
                if instance.isFlagged { Image(systemName: "flag.fill") }
            }
            .padding(.horizontal, 7)
            .frame(width: width, height: 32, alignment: .leading)
            .background(Color(hex: row.colorHex).opacity(store.selectedInstanceIDs.contains(instance.id) ? 1 : 0.75))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onTapGesture {
                store.selectInstance(rowID: row.id, instanceID: instance.id)
                selectedRowID = row.id
                currentTime = instance.startTime
            }
            .gesture(DragGesture().onEnded { value in
                let delta = Double(value.translation.width / 900) * max(duration, 1)
                store.updateInstance(rowID: row.id, instanceID: instance.id, startTime: instance.startTime + delta, endTime: instance.endTime + delta)
            })
            Rectangle().fill(.white.opacity(0.001)).frame(width: 8, height: 32)
                .gesture(DragGesture().onEnded { value in
                    let delta = Double(value.translation.width / 900) * max(duration, 1)
                    store.updateInstance(rowID: row.id, instanceID: instance.id, startTime: instance.startTime + delta)
                })
            Rectangle().fill(.white.opacity(0.001)).frame(width: 8, height: 32).offset(x: max(width - 8, 0))
                .gesture(DragGesture().onEnded { value in
                    let delta = Double(value.translation.width / 900) * max(duration, 1)
                    store.updateInstance(rowID: row.id, instanceID: instance.id, endTime: instance.endTime + delta)
                })
        }
        .frame(width: width, height: 32, alignment: .leading)
        .help(instance.note)
    }
}
