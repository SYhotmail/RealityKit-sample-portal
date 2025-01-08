//
//  WorldService.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 22/11/2024.
//

import Foundation
import RealityKit
import Synchronization

final class WorldService {
    
    let octopus = Octopus()
    
    private weak var portalWorld: Entity!
    
    lazy var hPlaneAnchorEntity: AnchorEntity = { 
       let result = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: .init(repeating: 0.1)), trackingMode: .once)
        result.name = "rootEntity"
       return result
    }()
    
    private let isLoadedCore = Mutex(false)
    
    private(set)var isLoaded: Bool {
        get {
            isLoadedCore.withLock { $0 }
        }
        set {
            isLoadedCore.withLock { value in
                value = newValue
            }
        }
    }
    
    func scheduleToLoadModels() {
        Task {
            Self.registerComponents()
            try await octopus.loadOctopus()
            await OctopusSystem.registerSystem()
            self.isLoaded = true
        }
    }
    
    private static func registerComponents() {
        OctopusComponent.registerComponent()
    }
    
    @discardableResult
    func anchorOctopusInScene( _ scene: Scene) -> Bool? {
        guard isLoaded, let octopus = octopus.octopusEntity else {
            return nil
        }
        
        guard octopus.scene != scene else {
            return false
        }
        
        scene.addAnchor(hPlaneAnchorEntity)
        return true
    }
    
    @MainActor
    func spawnPortal(scene: Scene) async throws {

        let tuple = try await Entity.makePortalToOuterspace()
        let portal = tuple.portal
        portal.position = .zero//[0, 1, -4]
        hPlaneAnchorEntity.addChild(portal)
        if var opacityComponent = portal.components[OpacityComponent.self] {
            opacityComponent.opacity = 0
            portal.components.set(opacityComponent)
        } else {
            portal.playFadeOpacityAnimation(to: 0, duration: 0)
        }
        
        scene.addAnchor(hPlaneAnchorEntity)
        
        let portalWorld = portal.components[PortalComponent.self]?.targetEntity
        self.portalWorld = portalWorld
        
        if let outerspace = portalWorld {
            
            var entitiesToAddToPortal = [Entity]()

            if let octopusEntity = octopus.octopusEntity {
                //octopusEntity.removeFromParent(preservingWorldTransform: true)
                octopusEntity.setPosition(.init(x: 0, y: -1, z: 0), relativeTo: portal)
                entitiesToAddToPortal.append(octopusEntity)
                
                async let copy1 = octopus.clonedEntity()
                async let copy2 = octopus.clonedEntity()
                await [copy1, copy2].compactMap { $0 }.forEach { copy in // copied octopuses just for visualization...
                    entitiesToAddToPortal.append(copy)
                }
            }

            for entity in entitiesToAddToPortal {
                entity.setParent(outerspace, preservingWorldTransform: true)
            }
        }
        
        portal.playFadeOpacityAnimation(from: 0, to: 1, duration: 0.2)
    }
}
