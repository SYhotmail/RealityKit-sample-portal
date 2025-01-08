//
//  ContentView.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 20/11/2024.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    var viewModel: ContentViewModel
    @State var octopusAnchor: Entity?
    
    
    @State var oldValue: CGFloat = 0
    
    @discardableResult
    private func addOctopusOnNeed(content: RealityViewCameraContent) -> Bool {
        guard let octopusAnchor, octopusAnchor.scene == nil else {
            return false
        }
        content.add(octopusAnchor)
        assert(octopusAnchor.scene != nil)
        return true
    }
    
    var octopusScale: Float {
        get { viewModel.worldService.octopus.scale }
        nonmutating set { viewModel.worldService.octopus.scale = newValue }
    }
    
    var customTap: some Gesture {
        SpatialTapGesture(count: 1)
            .targetedToAnyEntity()
            /*.targetedToEntity(where: .has(OctopusComponent.self)) */.onEnded({ targetedValue in
                let locationInScene =  targetedValue.locationInScene()
                
                //targetedValue.entity  - model entity
                if let octopusEntity = viewModel.worldService.octopus.octopusEntity {
                    var location2InScene = octopusEntity.convert(position: octopusEntity.position, to: nil)
                    
                    
                    location2InScene.z = locationInScene.z
                    
                    let value = distance(location2InScene, locationInScene)
                    //distance in the plane...
                    
                    //debugPrint("!!! value \(value)")
                    if value < 0.6 {
                        //assume octopus was pressed scaled......
                        debugPrint("!!! Location \(locationInScene)")
                        
                        //TODO: add some surface shader...
                    }
                }
            })
    }
    
    var body: some View {
        
        /*RealityView { content in
            if !addOctopusOnNeed(content: content) {
                Task {
                    let octopusModel = try await ModelEntity(named: Octopus.resourcePath(name: "octopus_posed"))
                    
                    let octopusEntity = Entity()
                    octopusModel.scale *= .init(repeating: 4.0)
                    octopusModel.generateCollisionShapes(recursive: true)
                    octopusModel.position.y -= octopusModel.visualBounds(relativeTo: nil).min.y
                    octopusEntity.addChild(octopusModel)
                    
                    let anchor = AnchorEntity(world: .zero)
                    anchor.addChild(octopusEntity)
                    self.octopusAnchor = anchor
                }
            }
            
            content.camera = .spatialTracking
        } update: { content in
            addOctopusOnNeed(content: content)
        } */

        
        RealityView { content in
            viewModel.provideRealityContent(content)
#if os(iOS)
            await content.setupWorldTracking()
            content.camera = .spatialTracking
#endif
        } update: { content in
            viewModel.provideRealityContent(content)
        } placeholder: {
            ProgressView().tint(.white)
        }.gesture(customTap)
        /*.gesture(
            MagnifyGesture(minimumScaleDelta: 0.1)
                .onChanged { gestureState in
                    let value = gestureState.magnification
                    let diff = value - oldValue
                    oldValue = value
                    debugPrint("!!! value \(value)")
                    let octopusScale = octopusScale + Float(diff)
                    //octopusScale = Float(value) // Update the scale dynamically
                    self.octopusScale = min(max(octopusScale, 0.1), 5) // Limit
                }.onEnded { value in
                    oldValue = 0
                }
        )
        .onTapGesture(count: viewModel.resetTapCount) {
            //
            octopusScale = 1.0
            oldValue = 0
        } */
        .ignoresSafeArea()

        /*RealityView { content in
            // Create the scene programmatically
            let sceneAnchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: .init(repeating: 0.2))) //AnchorEntity(world: .zero)
            // Create a box entity
            let box = ModelEntity(
                mesh: .generateBox(size: 0.2),
                materials: [SimpleMaterial(color: .blue, isMetallic: true)]
            )
            box.name = "RotatingBox"
            box.position = .init(repeating: 0.1)
            // Add the box to the anchor
            sceneAnchor.addChild(box)

            // Add the anchor to the scene
            content.add(sceneAnchor)
            content.camera = .spatialTracking
        } update: { content in
            // Rotate the box every frame
            guard let anchorEntity = content.entities.first as? AnchorEntity else {
                return
            }
            
            if let box = anchorEntity.findEntity(named: "RotatingBox") {
                let angle = Float(Date().timeIntervalSince1970).truncatingRemainder(dividingBy: .pi * 2)
                box.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
            }
        }
        .ignoresSafeArea() */
    }

}


#Preview {
    ContentView(viewModel: .init(worldService: .init()))
}
