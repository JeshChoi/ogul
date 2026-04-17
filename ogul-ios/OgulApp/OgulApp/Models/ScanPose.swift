import Foundation
import simd

/// One of the five standard head positions in the guided scan sequence.
enum ScanPose: String, CaseIterable, Identifiable {
    case front
    case turnLeft
    case turnRight
    case tiltUp
    case tiltDown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .front:      return "Face Forward"
        case .turnLeft:   return "Turn Left"
        case .turnRight:  return "Turn Right"
        case .tiltUp:     return "Tilt Up"
        case .tiltDown:   return "Tilt Down"
        }
    }

    var instruction: String {
        switch self {
        case .front:      return "Look straight into the camera"
        case .turnLeft:   return "Slowly turn your head to the left"
        case .turnRight:  return "Slowly turn your head to the right"
        case .tiltUp:     return "Tilt your chin slightly upward"
        case .tiltDown:   return "Tilt your chin slightly downward"
        }
    }

    var systemImage: String {
        switch self {
        case .front:      return "face.smiling"
        case .turnLeft:   return "arrow.turn.up.left"
        case .turnRight:  return "arrow.turn.up.right"
        case .tiltUp:     return "arrow.up"
        case .tiltDown:   return "arrow.down"
        }
    }

    // MARK: - Alignment detection thresholds (radians)

    /// Returns true when the face's current yaw/pitch is within the target window.
    func isAligned(yaw: Float, pitch: Float) -> Bool {
        switch self {
        case .front:
            return abs(yaw) < 0.15 && abs(pitch) < 0.15
        case .turnLeft:
            // User turns left → camera sees the right side of the face → yaw > 0
            return yaw > 0.35 && abs(pitch) < 0.25
        case .turnRight:
            return yaw < -0.35 && abs(pitch) < 0.25
        case .tiltUp:
            return pitch > 0.25 && abs(yaw) < 0.25
        case .tiltDown:
            return pitch < -0.20 && abs(yaw) < 0.25
        }
    }
}

/// A single pose's captured geometry.
struct PosedMesh {
    let pose: ScanPose
    /// Average of ~60 frames — noise-reduced face mesh vertices in face-local space.
    let localVertices: [simd_float3]
    /// localVertices transformed into ARKit world space.
    let worldVertices: [simd_float3]
    let triangleIndices: [Int16]
    /// Dense raw depth-map points in world space (2,000–8,000 per pose).
    /// Far more data than the 1220-vertex mesh; sampled directly from the TrueDepth sensor.
    let densePoints: [simd_float3]
    /// The ARFaceAnchor's world transform at the moment this pose was captured.
    /// Applying its inverse to densePoints converts them from world space into face-local space,
    /// which matches localVertices and always renders face-forward.
    let anchorTransform: simd_float4x4
    let capturedAt: Date

    static let identityTransform = matrix_identity_float4x4
}
