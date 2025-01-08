//
//  ContentViewModel.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 25/11/2024.
//

import Foundation
import RealityKit
import _RealityKit_SwiftUI


final class ContentViewModel {
    let worldService: WorldService
    private var subscription: EventSubscription!
    private var task: Task<Void, Error>?
    init(worldService: WorldService) {
        self.worldService = worldService
    }
    
    private func cancelSubscription() {
        subscription?.cancel()
    }
    
    deinit {
        cancelSubscription()
    }
    
    let resetTapCount = 2
    
    func provideRealityContent(_ content: RealityViewCameraContent) {
        
        cancelSubscription()
        subscription = content.subscribe(to: SceneEvents.Update.self, on: nil, componentType: nil) { [unowned self] event in
            
            let scene = event.scene
            if self.worldService.anchorOctopusInScene(scene) == true {
                if self.task == nil {
                    self.task = Task { @MainActor [scene] in
                        try await self.worldService.spawnPortal(scene: scene)
                        self.cancelSubscription()
                        self.task = nil
                    }
                }
            }
        }
    }
}
