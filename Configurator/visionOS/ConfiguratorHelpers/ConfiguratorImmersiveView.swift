// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import CloudXRKit
import SwiftUI
import RealityKit

struct ConfiguratorImmersiveView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(ConfiguratorAppModel.self) var configuratorAppModel
    @Environment(ConfiguratorViewModel.self) var configuratorViewModel
    
    @State private var sceneEntity = Entity()
    @State private var sessionEntity = Entity()
    @State private var spinnerEntity = Entity()

    @State private var cameraAnchor = Entity()
    @State private var placementManager = PlacementManager()

    // MARK: - Stream-only mode gate
    // Derived from existing session state: when true, only the remote CloudXR
    // stream is shown and all local decorative content is suppressed.
    private var isConnected: Bool {
        configuratorAppModel.session?.state == .connected
    }
    
    var body: some View {
        RealityView { content, attachments in
            placementManager.placeable = configuratorViewModel

            sceneEntity.name = "Scene"
            sessionEntity.name = "Session"
            spinnerEntity.name = "Spinner"

            if let session = configuratorAppModel.session {
                sessionEntity.components[CloudXRSessionComponent.self] = .init(session: session)
            }
            configuratorViewModel.sessionEntity = sessionEntity

            // MARK: CloudXR session entity
            // Always add the session entity: it is the attachment point for the
            // remote Omniverse / CloudXR stream and must be present in every state.
            content.add(sessionEntity)

            // MARK: Invisible gesture wall
            // The gesture-capture plane contains no visible geometry, so it is
            // safe to keep in all states (including connected / stream-only mode).
            cameraAnchor = Entity()
            content.add(cameraAnchor)
            cameraAnchor.addChild(makeInvisibleGestureWall())

            // MARK: Local decorative content – suppressed when connected
            // Before this change these entities were added unconditionally, which
            // caused the local template scene to overlap the remote stream once
            // CloudXR became active.  They are now only added while not yet
            // connected so that the connected state shows only the remote stream.

            // Always initialize the sceneEntity reference on the view-model so that
            // downstream consumers of configuratorViewModel.sceneEntity receive a
            // valid (if empty) entity even when the view launches in the connected state.
            configuratorViewModel.sceneEntity = sceneEntity

            if !isConnected {
                spinnerEntity = Entity()
                spinnerEntity.opacity = 1.0
                content.add(spinnerEntity)

                sceneEntity.components[ViewingModeComponent.self] = .init(
                    configuratorAppModel: configuratorAppModel,
                    configuratorViewModel: configuratorViewModel,
                    cloudXrEntity: sessionEntity,
                    spinnerEntity: spinnerEntity
                )
                sceneEntity.components[OpacityComponent.self] = .init(opacity: 0.0)

                // Local scene root – only added to content when not connected to avoid
                // overlapping the remote stream once CloudXR becomes active.
                content.add(sceneEntity)

                // Local animated decorative sphere – omitted when connected.
                content.add(makeMovingObject())
            }

            _ = content.subscribe(to:SceneEvents.Update.self,on: nil, componentType: nil) { frameData in
                if configuratorViewModel.viewIsLoading != configuratorAppModel.isAwaitingCompletion(viewingKey) {
                    configuratorViewModel.viewIsLoading = configuratorAppModel.isAwaitingCompletion(viewingKey)
                }
                
                let objectVisible = (configuratorAppModel.asset["objectVisibility"] as? GenericObjectVisibility == GenericObjectVisibility.visible)
                if configuratorViewModel.objectVisible != objectVisible {
                    configuratorViewModel.objectVisible = objectVisible
                }
            
                if let currentViewing = configuratorAppModel.asset[viewingKey] as? ViewingModel,
                   currentViewing != configuratorViewModel.currentViewing {
                     configuratorViewModel.currentViewing = currentViewing
                }
                if let headPose = configuratorAppModel.session?.latestHeadPose {
                    cameraAnchor.transform = headPose
                }
            }
        } update: { content, attachments in
            // MARK: Placement updates – suppressed when connected
            // Placement is a local-content feature; running it while the remote
            // stream is active could reintroduce local overlays.
            if !isConnected, let session = configuratorAppModel.session {
                placementManager.update(session: session, content: content, attachments: attachments)
            }
        } attachments: {
            // MARK: Placement attachments – suppressed when connected
            // Same reasoning as placement updates above.
            if !isConnected && configuratorViewModel.isPlacing {
                placementManager.attachments()
            }
        }
        .placing(with: placementManager, sceneEntity: sceneEntity, placeable: configuratorViewModel)
        .simultaneousGesture(configuratorAppModel.gestureHelper?.dragGesture)
        .simultaneousGesture(configuratorAppModel.gestureHelper?.rotationGesture)
        .simultaneousGesture(configuratorAppModel.gestureHelper?.magnifyGesture)
        .onChange(of: configuratorAppModel.session?.state) { oldState, newState in
            if newState == .connected {
                configuratorAppModel.asset.stateManager.startPolling()
                configuratorAppModel.asset.resync()
            } else {
                configuratorAppModel.asset.stateManager.stopPolling()
            }
        }
    }

    // TODO: Change this to the bounding box of the object sent from OV
    func makeInvisibleGestureWall() -> Entity {
        // Add an invisible plane that covers the viewport, attached to the headset that can accept gestures
        // so as to not get in the way of gestures on UI objects, the plane is 20 meters away.
        let plane = Entity()
        plane.components.set(InputTargetComponent())
        var collision = CollisionComponent(shapes: [.generateBox(width: 40, height: 40, depth: 0.01)])
        collision.mode = .trigger
        plane.components.set(collision)
        plane.position.z = -20
        return plane
    }

    /// Creates a local RealityKit sphere that continuously orbits in the immersive space,
    /// providing a moving 3D object independent of the remote CloudXR scene.
    func makeMovingObject() -> Entity {
        // Container that rotates, causing the sphere child to orbit around the container's origin
        let orbitContainer = Entity()
        orbitContainer.name = "MovingObjectContainer"
        orbitContainer.position = SIMD3<Float>(0, 1.5, -2.5)

        // Sphere positioned offset from container center so it orbits visibly
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .init(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0))
        material.roughness = .init(floatLiteral: 0.3)
        material.metallic = .init(floatLiteral: 0.7)
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.04), materials: [material])
        sphere.name = "MovingObjectSphere"
        sphere.position = SIMD3<Float>(0.3, 0, 0)
        orbitContainer.addChild(sphere)

        // Animate the container with a full rotation so the sphere orbits the container origin
        let fromTransform = Transform()
        var toTransform = Transform()
        toTransform.rotation = simd_quatf(angle: .pi * 2, axis: [0, 1, 0])

        if let orbitAnimation = try? AnimationResource.generate(with: FromToByAnimation(
            name: "orbit",
            from: fromTransform,
            to: toTransform,
            duration: 4.0,
            timing: .linear,
            isAdditive: false,
            repeatMode: .repeat,
            bindTarget: .transform
        )) {
            orbitContainer.playAnimation(orbitAnimation)
        }

        return orbitContainer
    }
}
