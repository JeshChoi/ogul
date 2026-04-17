import SwiftUI

/// ScanFlowView guides the user through a facial capture session.
/// Phase 1: placeholder UI — no ARKit yet.
/// Phase 2+: integrate ARKit TrueDepth session here.
struct ScanFlowView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var phase: ScanPhase = .guide
    @State private var progress: Double = 0.0
    @State private var notes: String = ""
    @State private var isUploading = false

    enum ScanPhase {
        case guide
        case scanning
        case review
        case uploading
        case done
    }

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .guide:    GuidePhaseView(onStart: startScan)
                case .scanning: ScanningPhaseView(progress: $progress, onComplete: completeScan)
                case .review:   ReviewPhaseView(notes: $notes, onUpload: uploadScan, onRetake: retake)
                case .uploading: UploadingPhaseView()
                case .done:     DonePhaseView(onDismiss: { dismiss() })
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if phase == .guide {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }

    private func startScan() {
        phase = .scanning
        // Phase 2+: start ARKit TrueDepth session
        simulateScan()
    }

    private func simulateScan() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            progress += 0.02
            if progress >= 1.0 {
                timer.invalidate()
                progress = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    phase = .review
                }
            }
        }
    }

    private func completeScan() {
        phase = .review
    }

    private func uploadScan() {
        phase = .uploading
        Task {
            let newScan = try? await APIService.shared.createScan(
                userId: appState.currentUserID,
                capturedAt: Date(),
                notes: notes
            )
            if let scan = newScan {
                await MainActor.run {
                    appState.scans.insert(scan, at: 0)
                    phase = .done
                }
            }
        }
    }

    private func retake() {
        progress = 0
        phase = .guide
    }
}

// MARK: - Phase Views

private struct GuidePhaseView: View {
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "face.smiling.inverse")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            VStack(spacing: 12) {
                Text("Position Your Face")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Hold your phone at eye level, about 30cm away. Ensure your face is well-lit and the guide aligns with your features.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 10) {
                GuideRow(icon: "sun.max", text: "Good, even lighting")
                GuideRow(icon: "arrow.up.and.down", text: "Phone at eye level")
                GuideRow(icon: "ruler", text: "~30cm from face")
                GuideRow(icon: "face.smiling", text: "Neutral expression")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: onStart) {
                Text("Begin Scan")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct GuideRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

private struct ScanningPhaseView: View {
    @Binding var progress: Double
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            // ARKit camera preview placeholder
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    VStack(spacing: 16) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.4))
                        Text("ARKit TrueDepth")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                        Text("(Phase 2)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.25))
                    }
                )
                .frame(height: 380)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(.blue)
                    .padding(.horizontal, 24)
                Text("Scanning… \(Int(progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

private struct ReviewPhaseView: View {
    @Binding var notes: String
    let onUpload: () -> Void
    let onRetake: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.green)
                .padding(.top, 40)

            Text("Scan Complete")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("How are you feeling today?", text: $notes, axis: .vertical)
                    .lineLimit(3...5)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button(action: onUpload) {
                    Text("Upload Scan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                Button(action: onRetake) {
                    Text("Retake")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

private struct UploadingPhaseView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Uploading scan…")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}

private struct DonePhaseView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "cloud.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.blue)

            Text("Uploaded!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your scan is being processed. Analytics will be available shortly.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
