import Foundation
import UIKit
import simd

/// Complete multi-pose facial scan result.
struct FaceMeshCapture {
    /// One entry per captured pose (up to 5).
    let posedMeshes: [PosedMesh]
    /// One photo snapshot per pose, in the same order as posedMeshes.
    let photos: [UIImage]
    let capturedAt: Date

    /// Convenience — first photo (front pose).
    var photo: UIImage? { photos.first }

    // MARK: - Derived

    /// Front pose mesh used for triangulated solid rendering.
    var frontMesh: PosedMesh? {
        posedMeshes.first { $0.pose == .front }
    }

    /// Combined dense depth-map points from all poses (up to ~40,000 real measurements).
    /// Use this for the highest-fidelity comparison between scans.
    var combinedPointCloud: [simd_float3] {
        let dense = posedMeshes.flatMap { $0.densePoints }
        // Fall back to mesh world vertices if depth data wasn't available
        return dense.isEmpty ? posedMeshes.flatMap { $0.worldVertices } : dense
    }

    var poseCount: Int   { posedMeshes.count }
    var totalPoints: Int { combinedPointCloud.count }

    /// How many raw depth measurements were captured across all poses.
    var densePointCount: Int { posedMeshes.reduce(0) { $0 + $1.densePoints.count } }

    // Convenience for backward compatibility with storage / display
    var vertexCount: Int    { frontMesh?.localVertices.count ?? 0 }
    var triangleCount: Int  { (frontMesh?.triangleIndices.count ?? 0) / 3 }
}
