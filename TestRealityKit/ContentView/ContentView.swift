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
            .onEnded({ targetedValue in
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
        .ignoresSafeArea()

    }

}


#Preview {
    ContentView(viewModel: .init(worldService: .init()))
}
