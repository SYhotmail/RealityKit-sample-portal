//
//  OctopusSystems.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 27/11/2024.
//

import RealityKit

struct OctopusComponent: RealityKit.Component {
    static let query = EntityQuery(where: .has(OctopusComponent.self))
    enum State {
        case insidePortal
        case movingAtTop(Double)
        case atTopOfPortal
    }
    var state: State = .insidePortal

    let animations: OctopusAnimations
}

struct OctopusSystem: RealityKit.System {
    let finalYPostion: Float = 0.1
    
    init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        let scene = context.scene
        for octopus in scene.performQuery(OctopusComponent.query) where octopus.isActive && Octopus.isRealOctopusEntity(octopus) {
            guard var component = octopus.components[OctopusComponent.self] else { continue }
            //guard component.settings?.octopus.fearsCamera ?? false else { return }
            switch component.state {
            case .insidePortal:
                /*guard let camera = scene.performQuery(CameraComponent.query).first(where: { _ in true }) else { continue }
                let fearDistance: Float = 1.0
                let distanceToCamera = octopus.distance(from: camera)

                guard distanceToCamera < fearDistance else { continue }
                guard let hidingLocation = scene.performQuery(OctopusHidingLocationComponent.query).max(by: {
                    $0.distance(from: camera) < $1.distance(from: camera)
                }) else { continue }

                let distance = octopus.distance(from: hidingLocation)
                guard distance > fearDistance else { continue } */
                let distance = Double(2)
                
                var duration = distance

                // Animations
                do {
                    let fixedTime
                        = component.animations.crawl2Swim.definition.duration
                        + component.animations.swim2Crawl.definition.duration
                    duration = max(fixedTime, duration)
                    let swimDuration = duration - fixedTime
                    let swimCycleDuration = component.animations.swim.definition.duration
                    let swimCycles = Int(swimDuration / swimCycleDuration)
                    duration = fixedTime + Double(swimCycles) * swimCycleDuration
                    debugPrint("swimCycles \(swimCycles)")
                    
                    let animResources: [AnimationResource] = [component.animations.crawl2Swim,
                                                              component.animations.swim.repeat(count: swimCycles),
                                                              component.animations.swim2Crawl]
                    let animation = try? AnimationResource.sequence(with: octopus.availableAnimations.isEmpty || false ? animResources : octopus.availableAnimations)
                    assert(animation != nil)
                    if let animation {
                        /*let expandedResouces = [animResources, [animation]].flatMap { $0 }
                        expandedResouces.forEach { animation in
                            if !octopus.availableAnimations.contains(where: { $0 === animation }) {
                                animation.store(in: octopus)
                            }
                        }
                        let controller = octopus.playAnimation(animation) */
                        
                        let controller = octopus.playAnimation(animation)
                        assert(controller.isPlaying && controller.isValid)
                    }
                }
                var transform = octopus.transform
                transform.translation = .init(repeating: 0) //move to the surface...
                transform.translation.y = finalYPostion
                
                debugPrint("!!! Duration \(duration)")
                octopus.move(to: transform, relativeTo: octopus.parent, duration: duration)
                //octopus.move(to: transform, relativeTo: nil, duration: duration)
                component.state = .movingAtTop(duration)
            case .movingAtTop(var time):
                time -= context.deltaTime
                component.state = time < 0 ? .atTopOfPortal : .movingAtTop(time)
            case .atTopOfPortal:
                if octopus.transform.translation.y != finalYPostion {
                    octopus.transform.translation.y = finalYPostion
                }
                
                octopus.setParent(scene.findEntity(named: "rootEntity"), preservingWorldTransform: true)
                
                return
            }
            octopus.components.set(component)
        }
    }
}
