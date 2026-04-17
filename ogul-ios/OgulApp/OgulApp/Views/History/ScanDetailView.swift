import SwiftUI
import SceneKit

struct ScanDetailView: View {
    let scan: Scan

    @State private var mesh: FaceMeshCapture?
    @State private var showingMesh = false
    @State private var renderMode: FaceMesh3DView.RenderMode = .solid
    @State private var selectedPoseIndex: Int = -1
    @State private var fullScreenPhotoIndex: Int? = nil   // non-nil = lightbox open

    private var poses: [ScanPose] { ScanPose.allCases }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                photoGallery
                Divider()
                if let mesh {
                    meshSection(mesh)
                }
                infoSection
            }
        }
        .navigationTitle("Scan Detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadLocalData)
        .fullScreenCover(isPresented: Binding(
            get: { fullScreenPhotoIndex != nil },
            set: { if !$0 { fullScreenPhotoIndex = nil } }
        )) {
            if let photos = mesh?.photos, !photos.isEmpty {
                PhotoLightbox(photos: photos,
                              poses: poses,
                              initialIndex: fullScreenPhotoIndex ?? 0)
            }
        }
    }

    // MARK: - Photo Gallery

    @ViewBuilder
    private var photoGallery: some View {
        let photos = mesh?.photos ?? []
        if photos.isEmpty {
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .frame(height: 280)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 56))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("No photos saved")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        } else {
            GalleryTabView(photos: photos,
                           poses: poses,
                           onTap: { index in fullScreenPhotoIndex = index })
        }
    }

    // MARK: - 3D Mesh Section

    @ViewBuilder
    private func meshSection(_ m: FaceMeshCapture) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("3D Scan Data")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("Solid")        { renderMode = .solid }
                    Button("Wireframe")    { renderMode = .wireframe }
                    Button("Point Cloud")  { renderMode = .pointCloud }
                } label: {
                    Label(renderModeLabel, systemImage: "cube")
                        .font(.caption).fontWeight(.medium)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }

            // Per-pose selector (only useful in point cloud mode)
            if renderMode == .pointCloud {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        DetailPosePill(label: "All Combined", selected: selectedPoseIndex == -1) {
                            selectedPoseIndex = -1
                        }
                        ForEach(Array(m.posedMeshes.enumerated()), id: \.offset) { i, posed in
                            let hasPoints = !posed.densePoints.isEmpty || !posed.worldVertices.isEmpty
                            if hasPoints {
                                DetailPosePill(label: posed.pose.title, selected: selectedPoseIndex == i) {
                                    selectedPoseIndex = i
                                }
                            }
                        }
                    }
                }
            }

            FaceMesh3DView(capture: m, mode: renderMode, poseIndex: selectedPoseIndex)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            // Stats row
            HStack(spacing: 0) {
                StatChip(value: "\(m.poseCount)", label: "poses")
                Divider().frame(height: 30)
                StatChip(value: "\(m.vertexCount)", label: "vertices")
                Divider().frame(height: 30)
                StatChip(value: "\(m.densePointCount)", label: "depth pts")
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Date + status
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(scan.capturedAt, style: .date)
                        .font(.title3).fontWeight(.bold)
                    Text(scan.capturedAt, style: .time)
                        .font(.subheadline).foregroundColor(.secondary)
                }
                Spacer()
                StatusPill(status: scan.status)
            }

            // Analytics
            if let a = scan.analytics {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Analytics").font(.headline)
                    HStack(spacing: 12) {
                        AnalyticTile(label: "Swelling",
                                     value: String(format: "%.1f%%", a.swellingPercent),
                                     color: .blue)
                        AnalyticTile(label: "Asymmetry",
                                     value: String(format: "%.2f", a.asymmetryScore),
                                     color: .purple)
                    }
                }
            }

            // Notes
            if !scan.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes").font(.headline)
                    Text(scan.notes)
                        .font(.body).foregroundColor(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                }
            }

            // Quality score
            if let q = scan.qualityScore {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scan Quality").font(.headline)
                    HStack {
                        ProgressView(value: q)
                            .tint(q > 0.8 ? .green : q > 0.6 ? .orange : .red)
                        Text(String(format: "%.0f%%", q * 100))
                            .font(.subheadline).foregroundColor(.secondary)
                            .frame(width: 44)
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Helpers

    private var renderModeLabel: String {
        switch renderMode {
        case .solid: return "Solid"
        case .wireframe: return "Wireframe"
        case .pointCloud: return "Point Cloud"
        }
    }

    private func loadLocalData() {
        if let path = scan.localMeshPath {
            DispatchQueue.global(qos: .userInitiated).async {
                let loaded = ScanStorageService.shared.loadMesh(path: path)
                DispatchQueue.main.async { mesh = loaded }
            }
        }
    }
}

// MARK: - Sub-views

// MARK: - Gallery tab view (tracks current page for tap-to-expand)

private struct GalleryTabView: View {
    let photos: [UIImage]
    let poses: [ScanPose]
    let onTap: (Int) -> Void

    @State private var currentPage = 0

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $currentPage) {
                ForEach(Array(photos.enumerated()), id: \.offset) { i, photo in
                    ZStack(alignment: .bottomLeading) {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .contentShape(Rectangle())
                            .onTapGesture { onTap(i) }

                        if i < poses.count {
                            Text(poses[i].title)
                                .font(.caption).fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(.black.opacity(0.5))
                                .clipShape(Capsule())
                                .padding(12)
                        }
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page)
            .frame(height: 300)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Expand hint
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(8)
                .background(.black.opacity(0.45))
                .clipShape(Circle())
                .padding(12)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Full-screen lightbox

private struct PhotoLightbox: View {
    let photos: [UIImage]
    let poses: [ScanPose]
    let initialIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1

    init(photos: [UIImage], poses: [ScanPose], initialIndex: Int) {
        self.photos = photos
        self.poses  = poses
        self.initialIndex = initialIndex
        _currentPage = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                ForEach(Array(photos.enumerated()), id: \.offset) { i, photo in
                    ZoomablePhoto(image: photo)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // Top overlay
            VStack {
                HStack {
                    // Pose label
                    if currentPage < poses.count {
                        Text(poses[currentPage].title)
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.black.opacity(0.5))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    // Close button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(.black.opacity(0.55))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }

            // Bottom counter
            VStack {
                Spacer()
                Text("\(currentPage + 1) / \(photos.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 40)
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Per-photo zoomable view

private struct ZoomablePhoto: View {
    let image: UIImage

    @State private var scale: CGFloat = 1
    @State private var anchor: UnitPoint = .center
    @State private var offset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1
    @GestureState private var gestureOffset: CGSize = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(max(1, scale * gestureScale), anchor: anchor)
            .offset(x: offset.width + gestureOffset.width,
                    y: offset.height + gestureOffset.height)
            .gesture(
                MagnifyGesture()
                    .updating($gestureScale) { value, state, _ in state = value.magnification }
                    .onEnded { value in
                        scale = max(1, scale * value.magnification)
                        if scale <= 1 { offset = .zero }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .updating($gestureOffset) { value, state, _ in
                        if scale > 1 { state = value.translation }
                    }
                    .onEnded { value in
                        if scale > 1 {
                            offset.width  += value.translation.width
                            offset.height += value.translation.height
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    scale = scale > 1 ? 1 : 2.5
                    if scale <= 1 { offset = .zero }
                }
            }
    }
}

private struct DetailPosePill: View {
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

private struct StatChip: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

private struct AnalyticTile: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}
