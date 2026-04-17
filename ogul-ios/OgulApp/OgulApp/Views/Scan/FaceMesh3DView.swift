import SwiftUI
import SceneKit
import simd

/// Renders a captured face mesh.
/// - Solid / Wireframe: uses the front-pose triangulated mesh (1220 vertices + triangles).
/// - Point Cloud: renders every world-space vertex from all poses (~6100 points total).
struct FaceMesh3DView: UIViewRepresentable {
    let capture: FaceMeshCapture
    var mode: RenderMode = .solid
    /// Which pose index to show in point cloud mode. -1 = show all combined.
    var poseIndex: Int = -1

    enum RenderMode { case solid, wireframe, pointCloud }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = buildScene()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.backgroundColor = UIColor(white: 0.07, alpha: 1)
        view.antialiasingMode = .multisampling4X
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Rebuild when mode changes
        uiView.scene = buildScene()
    }

    // MARK: - Scene

    private func buildScene() -> SCNScene {
        let scene = SCNScene()

        switch mode {
        case .solid, .wireframe:
            if let node = buildMeshNode() {
                scene.rootNode.addChildNode(node)
            }
        case .pointCloud:
            if let node = buildPointCloudNode() {
                scene.rootNode.addChildNode(node)
            }
        }

        addCamera(to: scene)
        addLights(to: scene)
        return scene
    }

    // MARK: - Front-pose triangulated mesh

    private func buildMeshNode() -> SCNNode? {
        guard let front = capture.frontMesh else { return nil }

        let positions = front.localVertices.map { SCNVector3($0.x, $0.y, $0.z) }
        let vertexSource = SCNGeometrySource(vertices: positions)
        let normalSource = SCNGeometrySource(normals: computeNormals(vertices: front.localVertices,
                                                                      indices: front.triangleIndices))
        let indexData = Data(bytes: front.triangleIndices,
                             count: front.triangleIndices.count * MemoryLayout<Int16>.size)
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .triangles,
                                         primitiveCount: front.triangleIndices.count / 3,
                                         bytesPerIndex: MemoryLayout<Int16>.size)

        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: [element])
        geometry.firstMaterial = meshMaterial()

        let node = SCNNode(geometry: geometry)
        node.scale = SCNVector3(8, 8, 8)
        return node
    }

    private func meshMaterial() -> SCNMaterial {
        let m = SCNMaterial()
        if mode == .wireframe {
            m.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.85)
            m.fillMode = .lines
        } else {
            m.diffuse.contents  = UIColor(red: 0.85, green: 0.72, blue: 0.63, alpha: 1)
            m.specular.contents = UIColor.white
            m.shininess = 0.25
            m.lightingModel = .phong
        }
        m.isDoubleSided = true
        return m
    }

    // MARK: - Point cloud (single pose or all combined)

    private func buildPointCloudNode() -> SCNNode? {
        // Collect raw world-space points for the selected pose(s)
        let rawPts: [simd_float3]
        if poseIndex >= 0 && poseIndex < capture.posedMeshes.count {
            let posed = capture.posedMeshes[poseIndex]
            rawPts = posed.densePoints.isEmpty ? posed.worldVertices : posed.densePoints
        } else {
            rawPts = capture.combinedPointCloud
        }
        guard !rawPts.isEmpty else { return nil }

        // Transform from ARKit world space → face-local space so the cloud is always
        // "face forward" (same coordinate space as the solid mesh's localVertices).
        // ARKit face-anchor local: +z points out of the face toward the camera viewer.
        // We use the front pose's anchor transform as the canonical reference frame.
        let pts: [simd_float3]
        if let frontMesh = capture.frontMesh,
           frontMesh.anchorTransform.columns.3 != matrix_identity_float4x4.columns.3 {
            // columns.3 is the translation — identity has (0,0,0,1), a real capture has a nonzero position
            let invT = simd_inverse(frontMesh.anchorTransform)
            pts = rawPts.map { p in
                let p4 = simd_float4(p.x, p.y, p.z, 1)
                let local = invT * p4
                return simd_float3(local.x, local.y, local.z)
            }
        } else {
            pts = rawPts
        }

        // Centre the cloud around its mean
        let mean = pts.reduce(simd_float3(0,0,0), +) / Float(pts.count)
        let centred = pts.map { $0 - mean }

        let positions = centred.map { SCNVector3($0.x, $0.y, $0.z) }
        let vertexSource = SCNGeometrySource(vertices: positions)

        // One index per point
        var indices = [Int32](0..<Int32(positions.count))
        let idxData = Data(bytes: &indices, count: indices.count * MemoryLayout<Int32>.size)
        let element = SCNGeometryElement(data: idxData,
                                         primitiveType: .point,
                                         primitiveCount: positions.count,
                                         bytesPerIndex: MemoryLayout<Int32>.size)
        element.pointSize = 2.5
        element.minimumPointScreenSpaceRadius = 1.5
        element.maximumPointScreenSpaceRadius = 4.0

        let geometry = SCNGeometry(sources: [vertexSource], elements: [element])
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.systemTeal
        m.lightingModel = .constant
        geometry.firstMaterial = m

        let node = SCNNode(geometry: geometry)
        node.scale = SCNVector3(8, 8, 8)
        return node
    }

    // MARK: - Camera & Lights

    private func addCamera(to scene: SCNScene) {
        let cam = SCNNode()
        cam.camera = SCNCamera()
        cam.camera?.zNear = 0.01
        cam.camera?.zFar = 100
        cam.camera?.fieldOfView = 42
        cam.position = SCNVector3(0, 0, 2.2)
        scene.rootNode.addChildNode(cam)
    }

    private func addLights(to scene: SCNScene) {
        // Key — front slightly above
        let key = SCNNode()
        key.light = { let l = SCNLight(); l.type = .directional; l.intensity = 1200; return l }()
        key.position = SCNVector3(0, 1, 4)
        key.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(key)

        // Fill — left side, cool tint
        let fill = SCNNode()
        fill.light = {
            let l = SCNLight()
            l.type = .directional
            l.intensity = 350
            l.color = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1)
            return l
        }()
        fill.position = SCNVector3(-3, 0.5, 2)
        fill.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(fill)

        // Ambient
        let amb = SCNNode()
        amb.light = { let l = SCNLight(); l.type = .ambient; l.intensity = 180; return l }()
        scene.rootNode.addChildNode(amb)
    }

    // MARK: - Normal computation

    private func computeNormals(vertices: [simd_float3], indices: [Int16]) -> [SCNVector3] {
        var normals = [simd_float3](repeating: .zero, count: vertices.count)
        stride(from: 0, to: indices.count, by: 3).forEach { i in
            let i0 = Int(indices[i]), i1 = Int(indices[i+1]), i2 = Int(indices[i+2])
            let n = simd_normalize(simd_cross(vertices[i1] - vertices[i0], vertices[i2] - vertices[i0]))
            normals[i0] += n; normals[i1] += n; normals[i2] += n
        }
        return normals.map {
            let l = simd_length($0)
            let n = l > 0 ? $0 / l : simd_float3(0, 0, 1)
            return SCNVector3(n.x, n.y, n.z)
        }
    }
}

