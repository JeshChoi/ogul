import SwiftUI
import ARKit

/// Walks the user through 5 standard head poses.
/// Each pose is captured manually — tap the shutter button when ready.
struct GuidedScanView: View {
    var onComplete: (FaceMeshCapture) -> Void
    var onCancel: () -> Void

    @State private var poseIndex = 0
    @State private var capturedMeshes: [PosedMesh] = []
    @State private var capturedPhotos: [UIImage] = []

    @State private var isTracking = false
    @State private var shouldCapture = false
    @State private var currentYaw: Float = 0
    @State private var currentPitch: Float = 0
    @State private var showFlash = false

    private let poses = ScanPose.allCases
    private var currentPose: ScanPose { poses[poseIndex] }
    private var isAligned: Bool { currentPose.isAligned(yaw: currentYaw, pitch: currentPitch) }

    var body: some View {
        ZStack {
            arView.ignoresSafeArea()
            faceGuide.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomPanel
            }
            if showFlash {
                Color.white.ignoresSafeArea()
                    .opacity(0.65)
                    .animation(.easeOut(duration: 0.2), value: showFlash)
            }
        }
    }

    // MARK: - AR View

    private var arView: some View {
        ARFaceView(
            activePose: currentPose,
            onAngleUpdate: { yaw, pitch in
                currentYaw = yaw
                currentPitch = pitch
            },
            onCapturePose: { posedMesh, photo in
                capturedMeshes.append(posedMesh)
                if let p = photo { capturedPhotos.append(p) }
                triggerFlash()
                advancePose()
            },
            shouldCapture: $shouldCapture,
            isTracking: $isTracking
        )
    }

    // MARK: - Face Guide Overlay

    /// A spotlight oval + crosshair that the user aligns their face into.
    /// The oval is intentionally fixed — same size/position every scan for consistency.
    private var faceGuide: some View {
        GeometryReader { geo in
            let ovalW  = geo.size.width  * 0.72
            let ovalH  = ovalW * 1.30
            let cx     = geo.size.width  / 2
            let cy     = geo.size.height * 0.40   // face sits in the upper half in portrait
            let ovalRect = CGRect(x: cx - ovalW / 2,
                                  y: cy - ovalH / 2,
                                  width: ovalW, height: ovalH)

            let lineColor = isAligned ? Color.green : Color.white
            let strokeW: CGFloat = isAligned ? 2.5 : 1.5

            ZStack {
                // ── Darkened surround (spotlight) ──────────────────────
                Canvas { ctx, size in
                    let full = Path(CGRect(origin: .zero, size: size))
                    var cutout = Path()
                    cutout.addEllipse(in: ovalRect)
                    var combined = full
                    combined.addPath(cutout)
                    // Even-odd fill punches the oval hole out of the dark overlay
                    ctx.fill(combined,
                             with: .color(.black.opacity(0.50)),
                             style: FillStyle(eoFill: true, antialiased: true))
                }

                // ── Oval border ────────────────────────────────────────
                Ellipse()
                    .stroke(lineColor, lineWidth: strokeW)
                    .frame(width: ovalW, height: ovalH)
                    .position(x: cx, y: cy)
                    .animation(.easeInOut(duration: 0.2), value: isAligned)

                // ── Corner tick marks (reinforce alignment zone) ────────
                ForEach(TickPosition.corners, id: \.id) { tick in
                    tick.path(cx: cx, cy: cy, ovalW: ovalW, ovalH: ovalH)
                        .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .animation(.easeInOut(duration: 0.2), value: isAligned)
                }

                // ── Crosshair at oval center ───────────────────────────
                let hairLen: CGFloat = 10
                let hairGap: CGFloat = 6
                Path { p in
                    p.move(to: CGPoint(x: cx - hairLen - hairGap, y: cy))
                    p.addLine(to: CGPoint(x: cx - hairGap, y: cy))
                    p.move(to: CGPoint(x: cx + hairGap, y: cy))
                    p.addLine(to: CGPoint(x: cx + hairLen + hairGap, y: cy))
                    p.move(to: CGPoint(x: cx, y: cy - hairLen - hairGap))
                    p.addLine(to: CGPoint(x: cx, y: cy - hairGap))
                    p.move(to: CGPoint(x: cx, y: cy + hairGap))
                    p.addLine(to: CGPoint(x: cx, y: cy + hairLen + hairGap))
                }
                .stroke(lineColor.opacity(0.5),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .animation(.easeInOut(duration: 0.2), value: isAligned)

                // ── "Nose goes here" centre dot ────────────────────────
                Circle()
                    .fill(lineColor.opacity(isAligned ? 0.9 : 0.35))
                    .frame(width: 5, height: 5)
                    .position(x: cx, y: cy)
                    .animation(.easeInOut(duration: 0.2), value: isAligned)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(.black.opacity(0.45))
                    .clipShape(Circle())
            }

            Spacer()

            // Progress dots
            HStack(spacing: 8) {
                ForEach(Array(poses.enumerated()), id: \.offset) { i, _ in
                    Circle()
                        .fill(dotColor(for: i))
                        .frame(width: 8, height: 8)
                        .scaleEffect(i == poseIndex ? 1.35 : 1.0)
                        .animation(.spring(duration: 0.3), value: poseIndex)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(isTracking ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                Text(isTracking ? "Tracking" : "Looking…")
                    .font(.caption2).foregroundColor(.white)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(.black.opacity(0.4))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                HStack(spacing: 12) {
                    Image(systemName: currentPose.systemImage)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentPose.title)
                            .font(.headline).foregroundColor(.white)
                        Text(currentPose.instruction)
                            .font(.subheadline).foregroundColor(.white.opacity(0.75))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                HStack(spacing: 6) {
                    Image(systemName: isAligned ? "checkmark.circle.fill" : "circle.dashed")
                        .foregroundColor(isAligned ? .green : .white.opacity(0.5))
                    Text(isAligned ? "Aligned — tap to capture" : "Fill the oval then tap")
                        .font(.caption)
                        .foregroundColor(isAligned ? .green : .white.opacity(0.6))
                }
            }

            // Shutter button
            Button(action: {
                guard isTracking else { return }
                shouldCapture = true
            }) {
                ZStack {
                    Circle()
                        .fill(isTracking ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 72, height: 72)
                    Circle()
                        .stroke(isAligned ? Color.green : Color.white.opacity(0.6),
                                lineWidth: 3)
                        .frame(width: 82, height: 82)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 26))
                        .foregroundColor(isTracking ? .black : .white.opacity(0.3))
                }
            }
            .disabled(!isTracking)
            .animation(.easeInOut(duration: 0.15), value: isTracking)

            Text("\(poseIndex + 1) of \(poses.count)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .padding(.bottom, 8)
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(colors: [.clear, .black.opacity(0.72)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    // MARK: - Helpers

    private func advancePose() {
        if poseIndex + 1 < poses.count {
            poseIndex += 1
        } else {
            onComplete(FaceMeshCapture(
                posedMeshes: capturedMeshes,
                photos: capturedPhotos,
                capturedAt: Date()
            ))
        }
    }

    private func triggerFlash() {
        showFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { showFlash = false }
    }

    private func dotColor(for index: Int) -> Color {
        if index < poseIndex  { return .green }
        if index == poseIndex { return .white }
        return .white.opacity(0.3)
    }
}

// MARK: - Corner tick mark helper

/// Describes one L-shaped corner tick mark around the oval.
private struct TickPosition {
    let id: Int
    let xSign: CGFloat   // +1 = right side, -1 = left side
    let ySign: CGFloat   // +1 = bottom, -1 = top
    let tickLen: CGFloat = 18

    static let corners: [TickPosition] = [
        TickPosition(id: 0, xSign: -1, ySign: -1),
        TickPosition(id: 1, xSign:  1, ySign: -1),
        TickPosition(id: 2, xSign: -1, ySign:  1),
        TickPosition(id: 3, xSign:  1, ySign:  1),
    ]

    /// Builds the L-shaped path at the corner of the oval bounding box plus a small inset.
    func path(cx: CGFloat, cy: CGFloat, ovalW: CGFloat, ovalH: CGFloat) -> Path {
        let inset: CGFloat = 6
        // Corner point on the bounding box, pulled in slightly
        let px = cx + xSign * (ovalW / 2 - inset)
        let py = cy + ySign * (ovalH / 2 - inset)
        return Path { p in
            // Horizontal leg
            p.move(to: CGPoint(x: px - xSign * tickLen, y: py))
            p.addLine(to: CGPoint(x: px, y: py))
            // Vertical leg
            p.addLine(to: CGPoint(x: px, y: py - ySign * tickLen))
        }
    }
}
