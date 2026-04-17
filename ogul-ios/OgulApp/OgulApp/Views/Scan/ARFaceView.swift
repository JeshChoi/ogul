import SwiftUI
import ARKit
import SceneKit

struct ARFaceView: UIViewRepresentable {

    /// The pose that will be labelled on the next capture.
    var activePose: ScanPose = .front

    /// Live yaw (left/right) and pitch (up/down) of the tracked face, in radians.
    var onAngleUpdate: ((Float, Float) -> Void)?

    /// Called when the coordinator should snapshot the current geometry + photo.
    var onCapturePose: ((PosedMesh, UIImage?) -> Void)?

    /// Flip to true to trigger a snapshot; resets to false automatically.
    @Binding var shouldCapture: Bool

    /// True while a face is actively being tracked.
    @Binding var isTracking: Bool

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.delegate = context.coordinator
        view.session.delegate = context.coordinator
        view.automaticallyUpdatesLighting = true
        view.rendersContinuously = true
        view.backgroundColor = .black

        context.coordinator.sceneView = view
        context.coordinator.onAngleUpdate = onAngleUpdate
        context.coordinator.onCapturePose = onCapturePose
        context.coordinator.onTrackingChanged = { tracking in
            DispatchQueue.main.async { isTracking = tracking }
        }

        context.coordinator.startSession()
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Keep callbacks and active pose fresh after every SwiftUI re-render
        context.coordinator.onAngleUpdate = onAngleUpdate
        context.coordinator.onCapturePose = onCapturePose
        context.coordinator.currentPose   = activePose

        guard shouldCapture else { return }
        context.coordinator.captureCurrentPose()
        DispatchQueue.main.async { shouldCapture = false }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        // Nil delegates before pausing so no callbacks fire on a dead coordinator
        uiView.delegate = nil
        uiView.session.delegate = nil
        uiView.session.pause()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var sceneView: ARSCNView?
        var onAngleUpdate: ((Float, Float) -> Void)?
        var onCapturePose: ((PosedMesh, UIImage?) -> Void)?
        var onTrackingChanged: ((Bool) -> Void)?

        private var currentFaceAnchor: ARFaceAnchor?
        var currentPose: ScanPose = .front

        // Multi-frame vertex accumulation — written from the render thread,
        // read/cleared from the main thread.  Protected by bufferLock.
        private var frameVertexBuffer: [[simd_float3]] = []
        private let bufferLock = NSLock()
        private let maxAccumulatedFrames = 60

        func startSession() {
            guard ARFaceTrackingConfiguration.isSupported else {
                print("[ARFaceView] Face tracking not supported.")
                return
            }
            let config = ARFaceTrackingConfiguration()
            config.isLightEstimationEnabled = true
            sceneView?.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        }

        // MARK: ARSCNViewDelegate

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let device = sceneView?.device,
                  let faceGeometry = ARSCNFaceGeometry(device: device) else { return nil }

            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.5)
            mat.fillMode = .lines
            mat.isDoubleSided = true
            faceGeometry.firstMaterial = mat

            currentFaceAnchor = faceAnchor
            onTrackingChanged?(true)
            return SCNNode(geometry: faceGeometry)
        }

        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor,
                  let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }

            faceGeometry.update(from: faceAnchor.geometry)
            currentFaceAnchor = faceAnchor

            // Accumulate frames — lock because captureCurrentPose reads/clears on main thread
            let verts = Array(faceAnchor.geometry.vertices)
            bufferLock.lock()
            frameVertexBuffer.append(verts)
            if frameVertexBuffer.count > maxAccumulatedFrames {
                frameVertexBuffer.removeFirst()
            }
            bufferLock.unlock()

            // Stream live face angles — weak self guards against coordinator dealloc
            let (yaw, pitch) = eulerAngles(from: faceAnchor.transform)
            DispatchQueue.main.async { [weak self] in
                self?.onAngleUpdate?(yaw, pitch)
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            guard anchor is ARFaceAnchor else { return }
            currentFaceAnchor = nil
            onTrackingChanged?(false)
        }

        // MARK: ARSessionDelegate

        func session(_ session: ARSession, didFailWithError error: Error) {
            print("[ARFaceView] Session error: \(error.localizedDescription)")
        }

        func sessionInterruptionEnded(_ session: ARSession) {
            startSession()
        }

        // MARK: Capture

        func captureCurrentPose() {
            guard let anchor = currentFaceAnchor,
                  let frame = sceneView?.session.currentFrame else {
                print("[ARFaceView] No face anchor or frame.")
                return
            }

            // Snapshot and clear the buffer atomically so the render thread can
            // keep appending without racing the average computation.
            bufferLock.lock()
            let bufferSnapshot = frameVertexBuffer
            frameVertexBuffer.removeAll(keepingCapacity: true)
            bufferLock.unlock()

            let avgLocal   = averagedVertices(from: bufferSnapshot, fallback: anchor.geometry)
            let indices    = Array(anchor.geometry.triangleIndices)
            let worldVerts = toWorldSpace(avgLocal, transform: anchor.transform)

            let densePoints = DenseDepthSampler.sample(from: frame, faceAnchor: anchor, step: 2)
            let photo = capturePhoto(frame: frame)

            let posed = PosedMesh(
                pose: currentPose,
                localVertices: avgLocal,
                worldVertices: worldVerts,
                triangleIndices: indices,
                densePoints: densePoints,
                anchorTransform: anchor.transform,
                capturedAt: Date()
            )

            print("[ARFaceView] Pose '\(currentPose.rawValue)': " +
                  "\(avgLocal.count) averaged vertices (\(bufferSnapshot.count) frames), " +
                  "\(densePoints.count) dense depth points")

            DispatchQueue.main.async { [weak self] in
                self?.onCapturePose?(posed, photo)
            }
        }

        /// Element-wise average of all accumulated frames; falls back to single frame.
        private func averagedVertices(from buffer: [[simd_float3]],
                                      fallback geo: ARFaceGeometry) -> [simd_float3] {
            guard !buffer.isEmpty, !buffer[0].isEmpty else { return Array(geo.vertices) }
            let n = Float(buffer.count)
            let count = buffer[0].count
            return (0..<count).map { i in
                buffer.reduce(simd_float3.zero) { $0 + $1[i] } / n
            }
        }

        // MARK: Helpers

        private func toWorldSpace(_ vertices: [simd_float3], transform: simd_float4x4) -> [simd_float3] {
            vertices.map { v in
                let v4 = simd_float4(v.x, v.y, v.z, 1.0)
                let w = transform * v4
                return simd_float3(w.x, w.y, w.z)
            }
        }

        private func eulerAngles(from transform: simd_float4x4) -> (yaw: Float, pitch: Float) {
            let fwd = transform.columns.2
            let yaw   = atan2(-fwd.x, -fwd.z)
            let pitch = asin(fwd.y)
            return (yaw, pitch)
        }

        private func capturePhoto(frame: ARFrame) -> UIImage? {
            let ci = CIImage(cvPixelBuffer: frame.capturedImage)
            let ctx = CIContext(options: [.useSoftwareRenderer: false])
            guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: cg, scale: 1.0, orientation: .right)
        }
    }
}
