import SwiftUI
import ARKit

struct ScanFlowView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var phase: Phase = .guide
    @State private var notes: String = ""
    @State private var capturedMesh: FaceMeshCapture?

    enum Phase { case guide, scanning, review, uploading, done }

    var body: some View {
        switch phase {

        case .guide:
            NavigationStack {
                GuidePhaseView(onStart: { phase = .scanning })
                    .navigationTitle("New Scan")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { dismiss() }
                        }
                    }
            }

        // Guided multi-pose scan — truly fullscreen, no NavStack
        case .scanning:
            GuidedScanView(
                onComplete: { mesh in
                    capturedMesh = mesh
                    phase = .review
                },
                onCancel: { phase = .guide }
            )
            .ignoresSafeArea()

        case .review:
            NavigationStack {
                ReviewPhaseView(
                    mesh: capturedMesh,
                    notes: $notes,
                    onUpload: uploadScan,
                    onRetake: { capturedMesh = nil; phase = .scanning }
                )
                .navigationTitle("Review Scan")
                .navigationBarTitleDisplayMode(.inline)
            }

        case .uploading:
            UploadingPhaseView()

        case .done:
            DonePhaseView(onDismiss: { dismiss() })
        }
    }

    private func uploadScan() {
        phase = .uploading
        Task {
            var newScan = try? await APIService.shared.createScan(
                userId: appState.currentUserID,
                capturedAt: capturedMesh?.capturedAt ?? Date(),
                notes: notes
            )
            if let capture = capturedMesh, let scanId = newScan?.id {
                let (photoPath, meshPath) = ScanStorageService.shared.save(capture, scanId: scanId)
                newScan?.localPhotoPath = photoPath
                newScan?.localMeshPath  = meshPath
            }
            await MainActor.run {
                if let scan = newScan { appState.scans.insert(scan, at: 0) }
                phase = .done
            }
        }
    }
}

// MARK: - Guide Phase

private struct GuidePhaseView: View {
    let onStart: () -> Void
    private let supported = ARFaceTrackingConfiguration.isSupported

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "face.smiling.inverse")
                .resizable().scaledToFit()
                .frame(width: 90, height: 90)
                .foregroundColor(.blue)

            VStack(spacing: 10) {
                Text("5-Pose Guided Scan")
                    .font(.title2).fontWeight(.bold)
                Text("You'll hold each position for about 1 second. The app auto-captures when your face is aligned.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            // Pose preview
            HStack(spacing: 0) {
                ForEach(ScanPose.allCases) { pose in
                    VStack(spacing: 6) {
                        Image(systemName: pose.systemImage)
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        Text(pose.title.components(separatedBy: " ").last ?? "")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
            .padding(.horizontal, 24)

            if !supported {
                Label("TrueDepth camera required (iPhone X or later)",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption).foregroundColor(.orange)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }

            Spacer()

            Button(action: onStart) {
                Text("Begin 5-Pose Scan")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(supported ? Color.blue : Color.gray)
                    .cornerRadius(14)
            }
            .disabled(!supported)
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }
}

// MARK: - Review Phase

private struct ReviewPhaseView: View {
    let mesh: FaceMeshCapture?
    @Binding var notes: String
    let onUpload: () -> Void
    let onRetake: () -> Void

    @State private var renderMode: FaceMesh3DView.RenderMode = .solid
    @State private var selectedPoseIndex: Int = 0

    private var poses: [ScanPose] { ScanPose.allCases }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let mesh {

                    // ── Photo strip ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Captured Photos")
                            .font(.headline)
                            .padding(.horizontal)

                        if mesh.photos.isEmpty {
                            Text("No photos saved")
                                .font(.caption).foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(mesh.photos.enumerated()), id: \.offset) { i, photo in
                                        VStack(spacing: 4) {
                                            Image(uiImage: photo)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 130)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            Text(i < poses.count ? poses[i].title : "Pose \(i+1)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // ── 3D Viewer ────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("3D Scan Data")
                                .font(.headline)
                            Spacer()
                            Menu {
                                Button("Solid")        { renderMode = .solid }
                                Button("Wireframe")    { renderMode = .wireframe }
                                Button("Point Cloud")  { renderMode = .pointCloud }
                            } label: {
                                Label(modeLabel, systemImage: "cube")
                                    .font(.caption).fontWeight(.medium)
                                    .padding(.horizontal, 10).padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)

                        // Pose selector (only meaningful in point cloud mode)
                        if renderMode == .pointCloud {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    PosePill(label: "All", selected: selectedPoseIndex == -1) {
                                        selectedPoseIndex = -1
                                    }
                                    ForEach(Array(mesh.posedMeshes.enumerated()), id: \.offset) { i, posed in
                                        PosePill(label: posed.pose.title, selected: selectedPoseIndex == i) {
                                            selectedPoseIndex = i
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        FaceMesh3DView(capture: mesh, mode: renderMode, poseIndex: selectedPoseIndex)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                    }

                    // ── Stats ─────────────────────────────────────────────
                    HStack(spacing: 0) {
                        StatCell(value: "\(mesh.poseCount)", label: "poses")
                        Divider().frame(height: 36)
                        StatCell(value: "\(mesh.vertexCount)", label: "mesh verts")
                        Divider().frame(height: 36)
                        StatCell(value: "\(mesh.densePointCount)", label: "depth pts")
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Notes
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes (optional)").font(.caption).foregroundColor(.secondary)
                    TextField("How are you feeling today?", text: $notes, axis: .vertical)
                        .lineLimit(3...5).padding(12)
                        .background(Color(.secondarySystemBackground)).cornerRadius(10)
                }
                .padding(.horizontal)

                // Actions
                VStack(spacing: 12) {
                    Button(action: onUpload) {
                        Text("Save Scan")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue).cornerRadius(14)
                    }
                    Button(action: onRetake) {
                        Text("Redo Scan").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal).padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
    }

    private var modeLabel: String {
        switch renderMode {
        case .solid: return "Solid"
        case .wireframe: return "Wireframe"
        case .pointCloud: return "Point Cloud"
        }
    }
}

private struct PosePill: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundColor(selected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

private struct StatCell: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
    }
}

// MARK: - Uploading & Done

private struct UploadingPhaseView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView().scaleEffect(1.5)
            Text("Saving scan…").foregroundColor(.secondary)
            Spacer()
        }
    }
}

private struct DonePhaseView: View {
    let onDismiss: () -> Void
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .resizable().scaledToFit().frame(width: 64, height: 64).foregroundColor(.green)
            Text("Scan Saved").font(.title2).fontWeight(.bold)
            Text("All 5 poses captured and stored. Analytics will update once processed.")
                .multilineTextAlignment(.center).foregroundColor(.secondary).padding(.horizontal, 32)
            Spacer()
            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).cornerRadius(14)
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }
}
