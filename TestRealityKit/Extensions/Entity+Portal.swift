/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Portal related Entity extensions.
*/

import RealityKit
import ImageIO

extension Entity {

    static func makePortalToOuterspace() async throws -> (portal: Entity, world: Entity) {
        let portal = Entity()
        portal.name = "Portal"
        let outerspace = try await makeOuterspace()
        portal.addChild(outerspace)
        portal.components.set(
            PortalComponent(
                target: outerspace,
                clippingMode: .disabled,//.plane(.positiveY),
                crossingMode: .plane(.positiveY)
            )
        )

        let dimension: Float = 0.8
        portal.components.set(
            ModelComponent(
                mesh: .generatePlane(width: dimension, depth: dimension, cornerRadius: ceil(dimension/2)),
                materials: [PortalMaterial()]
            )
        )
        
        let portalParticles = try! await Entity(named: "PortalParticles.usda")
        portalParticles.transform.rotation = .init(angle: .pi/2, axis: .init(x: 1, y: 0, z: 0))
        portalParticles.scale = SIMD3<Float>(repeating: 0.8 / 1.0)
        portal.addChild(portalParticles)
        

        return (portal: portal, world: outerspace)
    }

    // Create a large backdrop of outer space viewed through the portal.
    static func makeOuterspace() async throws -> Entity {
        
        // Create an outer space "world".
        let outerspace = Entity()
        outerspace.components.set(WorldComponent())
        outerspace.name = "Outer Space"
        
        let material = try await makeStarFieldMaterial()

        let starfield = Entity()
        starfield.components.set(
            ModelComponent(
                mesh: .generateSphere(radius: 20),
                materials: [material]
            )
        )

        // Ensure the texture image points inward at the viewer.
        starfield.scale *= .init(x: -1, y: 1, z: 1)
        outerspace.addChild(starfield)

        return outerspace
    }
    
    static func makeStarFieldMaterial() async throws -> UnlitMaterial {
        UnlitMaterial(color: .blue.withAlphaComponent(0.3))
    }
}
