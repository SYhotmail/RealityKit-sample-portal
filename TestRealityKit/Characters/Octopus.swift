//
//  Octopus.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 22/11/2024.
//

import Foundation
import RealityKit

struct OctopusAnimations {
    let crawl: AnimationResource
    let crawl2Swim: AnimationResource
    let swim: AnimationResource
    let swim2Crawl: AnimationResource
    
    enum Asset: String {
        case octopus_anim_crawl
        case octopus_anim_crawl_to_swim
        case octopus_anim_swim
        case octopus_anim_swim_to_crawl
    }
    
    init(crawl: AnimationResource, crawl2Swim: AnimationResource, swim: AnimationResource, swim2Crawl: AnimationResource) {
        self.crawl = crawl
        self.crawl2Swim = crawl2Swim
        self.swim = swim
        self.swim2Crawl = swim2Crawl
    }
    
    init?(dic: [OctopusAnimations.Asset: AnimationResource]) {
        let crawl = dic[.octopus_anim_crawl]
        let crawl2Swim = dic[.octopus_anim_crawl_to_swim]
        let swim = dic[.octopus_anim_swim]
        let swim2Crawl = dic[.octopus_anim_swim_to_crawl]
        
        guard let crawl, let crawl2Swim, let swim, let swim2Crawl else {
            return nil
        }
        self.init(crawl: crawl,
                  crawl2Swim: crawl2Swim,
                  swim: swim,
                  swim2Crawl: swim2Crawl)
    }
}
            
            

final class Octopus {
    
    private enum Constants {
        static let realName = "main"
        static let modelEnityName = "model"
    }
    
    private(set)var octopusEntity: Entity!
    
    @MainActor
    func clonedEntity() async -> Entity! {
        let clone = try? await Self.modelEntity(named: "octopus_anim_crawl")
        guard let entity = clone ?? octopusEntity?.clone(recursive: true) else {
            return nil
        }
        
        entity.transform.scale *= .init(repeating: 2)
        entity.components.remove(PortalCrossingComponent.self)
        if entity.components[CharacterControllerComponent.self] != nil {
            entity.moveCharacter(by: .init(x: Float(Double(arc4random_uniform(1)) * 0.25),
                                           y: 0,
                                           z: Float(Double(arc4random_uniform(1)) * 0.25)),
                                 deltaTime: 1,
                                 relativeTo: entity.parent) { collision in
            }
        } else {
            var transform = Transform()
            transform.translation = .init(x: Float(Double(arc4random_uniform(1)) * 0.25),
                                          y: 0,
                                          z: Float(Double(arc4random_uniform(1)) * 0.25))
            entity.move(to: transform, relativeTo: entity.parent, duration: 0.3)
        }
        let animations  = entity.availableAnimations
        
        let infinityAnimations = animations.map { $0.repeat(count: .max) }
        if let group = try? AnimationResource.sequence(with: infinityAnimations) {
            entity.playAnimation(group)
        }
        
        entity.name = ""
        return entity
    }
    
    private func loadOctopusAnimations() async throws -> [OctopusAnimations.Asset: AnimationResource] {
        
        async let animCrowl = Self.modelEntity(named:  OctopusAnimations.Asset.octopus_anim_crawl.rawValue)
        async let animSwim = Self.modelEntity(named: OctopusAnimations.Asset.octopus_anim_swim.rawValue)
        
        async let animCrawl2Swim = try Self.modelEntity(named: OctopusAnimations.Asset.octopus_anim_crawl_to_swim.rawValue)
        async let animSwim2Crawl = try Self.modelEntity(named: OctopusAnimations.Asset.octopus_anim_swim_to_crawl.rawValue)
        
        let dic : [OctopusAnimations.Asset: AnimationResource?] = await [.octopus_anim_swim_to_crawl: try Self.firstAnimationOrGrouped(entity: animSwim2Crawl),
                                                                          .octopus_anim_crawl: try Self.firstAnimationOrGrouped(entity: animCrowl),
                                                                         .octopus_anim_swim: try Self.firstAnimationOrGrouped(entity: animSwim),
                                                                         .octopus_anim_crawl_to_swim : try Self.firstAnimationOrGrouped(entity: animCrawl2Swim)]
        
        let result = dic.compactMapValues { $0 }
        assert(!result.isEmpty)
        return result
    }
    
    var scale: Float = 1.0 {
        didSet {
            guard scale != oldValue else {
                return
            }
            
            defineOctopusModelScale()
        }
    }
    
    private func defineOctopusModelScale() {
        guard let octopusEntity, let octopusModel = octopusEntity.findEntity(named: Constants.modelEnityName) as? ModelEntity else {
            return
        }
        octopusModel.scale = scaleSIM3D
    }
    
    private(set)var originalScale = SIMD3<Float>.one
    
    var scaleSIM3D: SIMD3<Float> {
        originalScale * scale
    }
    
    @MainActor func makeOctopusAnchorEntity(model octopusModel: Entity,
                                            animations: [OctopusAnimations.Asset : AnimationResource]) -> Entity {
        
        let octopusEntity = Entity()
        debugPrint("!! scale \(octopusModel.scale)")
        originalScale = 4 * octopusModel.scale
        
        let bounds = octopusModel.visualBounds(relativeTo: nil)
        octopusModel.name = Constants.modelEnityName
        debugPrint(" bounds.extents \(bounds.extents)")
        octopusModel.position.y -= bounds.min.y //bottom on zero....
        octopusEntity.addChild(octopusModel)
        
        if let component = OctopusAnimations(dic: animations).flatMap({ OctopusComponent(animations: $0) }) {
            // octopusEntity
            animations.values.forEach { resource in
                if !octopusEntity.availableAnimations.contains(where: { $0 === resource }) {
                    resource.store(in: octopusEntity)
                }
            }
            assert(!octopusEntity.availableAnimations.isEmpty)
            octopusEntity.components.set(component)
        }
        
        octopusEntity.components.set(PortalCrossingComponent())
        octopusEntity.generateCollisionShapes(recursive: true)
        
        if octopusEntity.components[CollisionComponent.self] == nil {
            var collision = CollisionComponent(shapes: octopusModel.components[CollisionComponent.self]!.shapes)
            collision.filter = .init(group: [], mask: [])
            octopusEntity.components.set(collision)
        }
        
        if octopusEntity.components[CollisionComponent.self] != nil {
            octopusEntity.components.set(InputTargetComponent())
        }
        
        octopusEntity.name = Constants.realName
        return octopusEntity
    }
    
    static func isRealOctopusEntity(_ entity: Entity) -> Bool {
        entity.name == Constants.realName
    }
    
    func loadOctopus() async throws {
        async let posedOctopusModel = try Self.modelEntity(named: "octopus_posed")
        //let anims = try await posedOctopusModel.availableAnimations
        //debugPrint("!! anims \(anims.map { $0.name } )")
        let octopusModel = try await posedOctopusModel
        
        let octopusAnims = try await loadOctopusAnimations()
        debugPrint("!!! animations count \(octopusAnims.count)")
        assert(!octopusAnims.isEmpty)
        await MainActor.run { [weak self] in
            guard let self else {
                return
            }
            
            let entity = self.makeOctopusAnchorEntity(model: octopusModel,
                                                      animations: octopusAnims)
            self.octopusEntity = entity
            self.defineOctopusModelScale()
        }
    }
    
    static func resourcePath(_ path: String) -> String {
        "Octopus/\(path)"
    }
    
    static func resourcePath(name: String, ext: String = ".usdc") -> String {
        resourcePath(name + ext)
    }
    
    static func modelEntity<T: RawRepresentable>(_ type: T) async throws -> ModelEntity where T.RawValue == String {
        try await modelEntity(named: type.rawValue)
    }
    
    static func modelEntity(named name: String) async throws -> ModelEntity {
        let bundle = Bundle(for: self)
        return try await ModelEntity(named: resourcePath(name: name), in: bundle)
    }
    
    static func entity<T: RawRepresentable> (_ type: T) async throws -> Entity where T.RawValue == String {
        try await entity(named: type.rawValue)
    }
    
    static func entity(named name: String) async throws -> Entity {
        let bundle = Bundle(for: self)
        return try await Entity(named: resourcePath(name: name), in: bundle)
    }
    
    static func firstAnimationOrGrouped(entity: Entity) throws -> AnimationResource! {
        guard let first = entity.availableAnimations.first else {
            return nil
        }
        
        return entity.availableAnimations.count > 1 ? try AnimationResource.group(with: entity.availableAnimations) : first
    }
}
