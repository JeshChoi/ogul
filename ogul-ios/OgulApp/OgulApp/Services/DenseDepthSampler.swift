import ARKit
import simd

/// Samples the raw TrueDepth sensor buffer from an ARFrame and returns a dense
/// 3D point cloud of the face region in world space.
///
/// Why: ARKit's ARFaceAnchor mesh is fixed at 1220 vertices. The underlying
/// TrueDepth sensor produces a ~320×240 depth map — far more raw data.
/// This unpacks that data and filters it to the face bounding sphere.
struct DenseDepthSampler {

    /// - Parameters:
    ///   - frame:      The current ARFrame (contains capturedDepthData).
    ///   - faceAnchor: Used to determine the face's world-space position for filtering.
    ///   - step:       Sample every Nth pixel. 1 = maximum density, 2 = half density (faster).
    /// - Returns: World-space 3D points covering the detected face region.
    static func sample(
        from frame: ARFrame,
        faceAnchor: ARFaceAnchor,
        step: Int = 2
    ) -> [simd_float3] {

        guard let rawDepth = frame.capturedDepthData else { return [] }

        // Ensure float32 depth format
        let depthData = rawDepth.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32)
        let depthMap = depthData.depthDataMap

        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }

        let mapWidth  = CVPixelBufferGetWidth(depthMap)
        let mapHeight = CVPixelBufferGetHeight(depthMap)
        guard let base = CVPixelBufferGetBaseAddress(depthMap) else { return [] }
        let depthPtr = base.assumingMemoryBound(to: Float32.self)

        // Scale camera calibration intrinsics to match the actual depth map resolution
        guard let cal = depthData.cameraCalibrationData else { return [] }
        let K   = cal.intrinsicMatrix
        let ref = cal.intrinsicMatrixReferenceDimensions
        let sx  = Float(mapWidth)  / Float(ref.width)
        let sy  = Float(mapHeight) / Float(ref.height)
        let fx  = K[0][0] * sx
        let fy  = K[1][1] * sy
        let cx  = K[2][0] * sx
        let cy  = K[2][1] * sy

        // Face bounding sphere in world space
        let col3    = faceAnchor.transform.columns.3
        let facePos = simd_float3(col3.x, col3.y, col3.z)
        let radius: Float = 0.14   // 14 cm covers the full face

        let cam = frame.camera.transform
        var points = [simd_float3]()
        points.reserveCapacity((mapWidth / step) * (mapHeight / step) / 4)

        for row in stride(from: 0, to: mapHeight, by: step) {
            for col in stride(from: 0, to: mapWidth, by: step) {
                let d = depthPtr[row * mapWidth + col]
                // Discard invalid or out-of-range depth
                guard d > 0.08 && d < 0.70 else { continue }

                // Project pixel → camera space
                // ARKit convention: camera looks down -Z, Y is up
                let xCam =  (Float(col) - cx) / fx * d
                let yCam = -((Float(row) - cy) / fy) * d
                let zCam = -d

                // Camera → world space
                let camPt  = simd_float4(xCam, yCam, zCam, 1.0)
                let wPt4   = cam * camPt
                let wPt    = simd_float3(wPt4.x, wPt4.y, wPt4.z)

                // Keep only points inside the face bounding sphere
                if simd_length(wPt - facePos) < radius {
                    points.append(wPt)
                }
            }
        }

        return points
    }
}
