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
                        NavigationLink(destination: ScanDetailView(scan: scan)) {
                            ScanRow(scan: scan)
                        }
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

// MARK: - Scan Row

struct ScanRow: View {
    let scan: Scan
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 64, height: 64)

                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "face.smiling")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(scan.capturedAt, style: .date)
                        .font(.subheadline).fontWeight(.semibold)
                    Spacer()
                    StatusPill(status: scan.status)
                }
                Text(scan.capturedAt, style: .time)
                    .font(.caption).foregroundColor(.secondary)

                if let analytics = scan.analytics {
                    HStack(spacing: 10) {
                        Label(String(format: "%.1f%%", analytics.swellingPercent),
                              systemImage: "waveform.path")
                            .font(.caption).foregroundColor(.blue)
                        Label(String(format: "%.2f", analytics.asymmetryScore),
                              systemImage: "arrow.left.and.right")
                            .font(.caption).foregroundColor(.purple)
                    }
                }

                if !scan.notes.isEmpty {
                    Text("\"\(scan.notes)\"")
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(1)
                        .italic()
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .onAppear(perform: loadThumbnail)
    }

    private func loadThumbnail() {
        guard thumbnail == nil, let path = scan.localPhotoPath else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let img = ScanStorageService.shared.loadPhoto(path: path)
            DispatchQueue.main.async { thumbnail = img }
        }
    }
}

// MARK: - Status Pill

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
            .font(.caption2).fontWeight(.medium)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
