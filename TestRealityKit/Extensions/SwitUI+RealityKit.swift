//
//  SwitUI+RealityKit.swift
//  TestRealityKit
//
//  Created by Siarhei Yakushevich on 07/01/2025.
//

import SwiftUI
import RealityKit

extension EntityTargetValue<SpatialTapGesture.Value> {
    func locationInScene() -> SIMD3<Float> {
#if os(visionOS)
        return convert(self.location3D, from: .local, to: .scene)
#elseif os(iOS)
        if let (origin, direction) = ray(through: self.location, in: .local, to: .scene) {
           return origin + length(entity.position - origin) * direction
        }
        return .zero
#endif
    }
}
