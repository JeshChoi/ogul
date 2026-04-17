import SwiftUI

struct ScanHistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingScanFlow = false

    private var sortedScans: [Scan] {
        appState.scans.sorted { $0.capturedAt > $1.capturedAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedScans.isEmpty {
                    ContentUnavailableView(
                        "No Scans Yet",
                        systemImage: "camera.fill",
                        description: Text("Perform your first scan to start tracking recovery.")
                    )
                } else {
                    List(sortedScans) { scan in
                        ScanRow(scan: scan)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Scan History")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingScanFlow = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingScanFlow) {
                ScanFlowView()
            }
        }
    }
}

struct ScanRow: View {
    let scan: Scan

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(scan.capturedAt, style: .date)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(scan.capturedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                StatusPill(status: scan.status)
            }

            if !scan.notes.isEmpty {
                Text("\"\(scan.notes)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            if let analytics = scan.analytics {
                HStack(spacing: 16) {
                    Label(
                        String(format: "%.1f%% swelling", analytics.swellingPercent),
                        systemImage: "waveform.path"
                    )
                    .font(.caption)
                    .foregroundColor(.blue)

                    Label(
                        String(format: "%.2f asymmetry", analytics.asymmetryScore),
                        systemImage: "arrow.left.and.right"
                    )
                    .font(.caption)
                    .foregroundColor(.purple)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

struct StatusPill: View {
    let status: ScanStatus

    private var color: Color {
        switch status {
        case .complete:   return .green
        case .processing: return .orange
        case .failed:     return .red
        case .uploaded:   return .blue
        default:          return .gray
        }
    }

    var body: some View {
        Text(status.displayLabel)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
