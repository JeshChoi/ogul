import UIKit
import simd

/// Persists scan photos and mesh data to the app's Documents directory.
///
/// Layout per scan:
///   photo_0.jpg           — pose-0 JPEG snapshot (front)
///   photo_1.jpg           — pose-1 JPEG snapshot (turn-left) … etc.
///   mesh.bin              — front-pose triangulated mesh (vertices + indices)
///   pointcloud_0.bin      — front-pose dense depth points
///   pointcloud_1.bin      — turn-left dense depth points … etc.
final class ScanStorageService {
    static let shared = ScanStorageService()

    private let base: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        base = docs.appendingPathComponent("ogul_scans", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
    }

    // MARK: - Save

    @discardableResult
    func save(_ capture: FaceMeshCapture, scanId: String) -> (photoPath: String?, meshPath: String?) {
        let dir = base.appendingPathComponent(scanId, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // One photo per pose
        for (i, photo) in capture.photos.enumerated() {
            if let data = photo.jpegData(compressionQuality: 0.85) {
                try? data.write(to: dir.appendingPathComponent("photo_\(i).jpg"))
            }
        }

        // Per-pose point clouds — include anchor transform so reload renders face-forward
        for (i, posed) in capture.posedMeshes.enumerated() {
            let pts = posed.densePoints.isEmpty ? posed.worldVertices : posed.densePoints
            savePoints(pts, transform: posed.anchorTransform,
                       to: dir.appendingPathComponent("pointcloud_\(i).bin"))
        }

        let photoPath = capture.photos.isEmpty ? nil :
            dir.appendingPathComponent("photo_0.jpg").path
        let meshPath = saveMesh(capture, to: dir)

        return (photoPath, meshPath)
    }

    // MARK: - Save helpers

    private func saveMesh(_ capture: FaceMeshCapture, to dir: URL) -> String? {
        guard let front = capture.frontMesh else { return nil }
        var data = Data()

        var vc = Int32(front.localVertices.count)
        data.append(Data(bytes: &vc, count: 4))
        for v in front.localVertices {
            var x = v.x, y = v.y, z = v.z
            data.append(Data(bytes: &x, count: 4))
            data.append(Data(bytes: &y, count: 4))
            data.append(Data(bytes: &z, count: 4))
        }

        var ic = Int32(front.triangleIndices.count)
        data.append(Data(bytes: &ic, count: 4))
        data.append(front.triangleIndices.withUnsafeBytes { Data($0) })

        let url = dir.appendingPathComponent("mesh.bin")
        try? data.write(to: url)
        return url.path
    }

    private func savePoints(_ points: [simd_float3], transform: simd_float4x4 = matrix_identity_float4x4, to url: URL) {
        var data = Data()
        // 16 floats — the 4×4 anchor transform (face-local ↔ world mapping)
        var t = transform
        data.append(Data(bytes: &t, count: MemoryLayout<simd_float4x4>.size))
        var count = Int32(points.count)
        data.append(Data(bytes: &count, count: 4))
        for p in points {
            var x = p.x, y = p.y, z = p.z
            data.append(Data(bytes: &x, count: 4))
            data.append(Data(bytes: &y, count: 4))
            data.append(Data(bytes: &z, count: 4))
        }
        try? data.write(to: url)
    }

    // MARK: - Load

    func loadPhoto(path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    /// Loads the mesh and all per-pose point clouds, restoring correct pose labels.
    func loadMesh(path: String) -> FaceMeshCapture? {
        guard let data = FileManager.default.contents(atPath: path) else { return nil }

        var offset = 0
        func readInt32() -> Int {
            let v = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) })
            offset += 4; return v
        }
        func readFloat() -> Float {
            let v = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Float.self) }
            offset += 4; return v
        }

        let vc = readInt32()
        var vertices = [simd_float3](); vertices.reserveCapacity(vc)
        for _ in 0..<vc { vertices.append(simd_float3(readFloat(), readFloat(), readFloat())) }

        let ic = readInt32()
        var indices = [Int16](); indices.reserveCapacity(ic)
        for _ in 0..<ic {
            let v = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int16.self) }
            indices.append(v); offset += 2
        }

        let dir = URL(fileURLWithPath: path).deletingLastPathComponent()
        let allPoses = ScanPose.allCases

        // Load per-pose point clouds, assigning the correct ScanPose to each
        var posedMeshes: [PosedMesh] = []
        var i = 0
        while true {
            let pcURL = dir.appendingPathComponent("pointcloud_\(i).bin")
            guard FileManager.default.fileExists(atPath: pcURL.path) else { break }
            let (pts, transform) = loadPointsAndTransform(from: pcURL)
            let pose = i < allPoses.count ? allPoses[i] : .front

            if i == 0 {
                posedMeshes.append(PosedMesh(pose: pose,
                                             localVertices: vertices,
                                             worldVertices: [],
                                             triangleIndices: indices,
                                             densePoints: pts,
                                             anchorTransform: transform,
                                             capturedAt: Date()))
            } else {
                posedMeshes.append(PosedMesh(pose: pose,
                                             localVertices: [],
                                             worldVertices: [],
                                             triangleIndices: [],
                                             densePoints: pts,
                                             anchorTransform: transform,
                                             capturedAt: Date()))
            }
            i += 1
        }

        // Legacy fallback: single combined pointcloud.bin (old saves, no transform stored)
        if posedMeshes.isEmpty {
            let legacyURL = dir.appendingPathComponent("pointcloud.bin")
            let (pts, _) = loadPointsAndTransform(from: legacyURL)
            posedMeshes = [
                PosedMesh(pose: .front,
                          localVertices: vertices,
                          worldVertices: [],
                          triangleIndices: indices,
                          densePoints: pts,
                          anchorTransform: matrix_identity_float4x4,
                          capturedAt: Date())
            ]
        }

        // Load all pose photos
        var photos: [UIImage] = []
        var j = 0
        while true {
            let url = dir.appendingPathComponent("photo_\(j).jpg")
            guard let img = UIImage(contentsOfFile: url.path) else { break }
            photos.append(img)
            j += 1
        }

        return FaceMeshCapture(posedMeshes: posedMeshes,
                               photos: photos,
                               capturedAt: Date())
    }

    /// Reads a point cloud file. New format has a 64-byte 4×4 matrix header before the count.
    /// Legacy files (just count + points) return identity transform.
    private func loadPointsAndTransform(from url: URL) -> ([simd_float3], simd_float4x4) {
        let matrixBytes = MemoryLayout<simd_float4x4>.size  // 64
        guard let data = FileManager.default.contents(atPath: url.path) else { return ([], matrix_identity_float4x4) }

        var offset = 0
        var transform = matrix_identity_float4x4

        // New format: starts with 64-byte matrix then Int32 count
        // Legacy format: starts directly with Int32 count (≤ max sensible count)
        // Distinguish by checking if interpreting the first 4 bytes as Int32 gives a plausible count
        // for a legacy file.  New files always have 64+ bytes before the count field.
        let hasTransform = data.count >= matrixBytes + 4
        if hasTransform {
            transform = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: simd_float4x4.self) }
            offset = matrixBytes
        }

        guard data.count >= offset + 4 else { return ([], transform) }
        let count = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) })
        offset += 4

        // Sanity check: legacy files have a small count at byte 0; reject if it looks like a matrix
        // (a 4×4 rotation matrix has values near 1.0, which interpreted as Int32 would be huge).
        // If count is unreasonably large, assume this is actually a legacy file with no matrix.
        if count < 0 || count > 200_000 {
            // Re-read as legacy
            var o2 = 0
            let c2 = Int(data.withUnsafeBytes { $0.load(fromByteOffset: o2, as: Int32.self) })
            o2 += 4
            guard c2 > 0, c2 <= 200_000 else { return ([], matrix_identity_float4x4) }
            var pts = [simd_float3](); pts.reserveCapacity(c2)
            for _ in 0..<c2 {
                let x = data.withUnsafeBytes { $0.load(fromByteOffset: o2,     as: Float.self) }
                let y = data.withUnsafeBytes { $0.load(fromByteOffset: o2 + 4, as: Float.self) }
                let z = data.withUnsafeBytes { $0.load(fromByteOffset: o2 + 8, as: Float.self) }
                pts.append(simd_float3(x, y, z)); o2 += 12
            }
            return (pts, matrix_identity_float4x4)
        }

        var pts = [simd_float3](); pts.reserveCapacity(count)
        for _ in 0..<count {
            guard offset + 12 <= data.count else { break }
            let x = data.withUnsafeBytes { $0.load(fromByteOffset: offset,     as: Float.self) }
            let y = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: Float.self) }
            let z = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: Float.self) }
            pts.append(simd_float3(x, y, z)); offset += 12
        }
        return (pts, transform)
    }
}
