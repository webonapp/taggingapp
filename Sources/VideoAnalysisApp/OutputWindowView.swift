import SwiftUI

struct OutputWindowView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var script = "# Una istruzione per riga\nCOUNT Eventi totali\nDURATION Durata analisi\nCOUNT_LABEL Occasione creata"
    @State private var metrics: [OutputMetric] = []

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text("Script Output Window").font(.headline)
                TextEditor(text: $script).font(.system(.body, design: .monospaced)).border(.secondary.opacity(0.3))
                Button("Esegui") { metrics = OutputScriptEngine.execute(script, project: store.project) }
            }
            .padding()
            Divider()
            VStack(alignment: .leading) {
                Text("Risultato").font(.headline)
                ForEach(metrics) { metric in
                    HStack { Text(metric.title); Spacer(); Text(metric.value).bold().monospacedDigit() }
                        .padding(8).background(.purple.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Spacer()
            }
            .padding()
            .frame(width: 300)
        }
        .frame(minWidth: 800, minHeight: 480)
    }
}
