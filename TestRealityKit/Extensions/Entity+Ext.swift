//
//  Entity+Ext.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 03/01/2025.
//

import RealityKit

extension Entity {
    @discardableResult
    func playFadeOpacityAnimation(from start: Float? = nil, to end: Float, duration: Double) -> AnimationPlaybackController {
        let start = start ?? components[OpacityComponent.self]?.opacity ?? 0
        let fadenimationDefinition = FromToByAnimation(
            from: Float(start),
            to: Float(end),
            duration: duration,
            timing: .easeInOut,
            bindTarget: .opacity
        )
        let fadeInAnimation = try! AnimationResource.generate(with: fadenimationDefinition)
        components.set(OpacityComponent(opacity: start))
        
        return playAnimation(fadeInAnimation)
    }
}

