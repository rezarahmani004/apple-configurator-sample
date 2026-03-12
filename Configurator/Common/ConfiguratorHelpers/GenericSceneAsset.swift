// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import Foundation

// Event type used by variant-selection messages sent to the Omniverse server.
let setGenericVariantEventType = "setVariantSelection"

// MARK: - Camera

/// Represents a named camera in the Omniverse scene.
class GenericCamera: AssetCamera {
    init(_ ovName: String = "") {
        super.init(
            ovName: ovName,
            description: ovName.replacingOccurrences(of: "_", with: " "),
            encodable: GenericCameraClientInputEvent(ovName)
        )
    }
}

// MARK: - Asset

/// A neutral Omniverse scene asset that acts as a pure camera client/viewer.
///
/// This asset does **not** send any scene-specific variant state (environment,
/// color, material style, object visibility) to the Omniverse server on connect.
/// It only tracks the portal/tabletop viewing mode, which is required for the
/// local camera and rendering pipeline.
///
/// All scene content is supplied by the remote Omniverse stream; no default
/// room, environment, or decorative objects are created locally.
public class GenericSceneAsset: AssetModel {

    /// Cameras available for selection in the Omniverse scene.
    let exteriorSceneCameras: [AssetCamera] = [
        GenericCamera("Front"),
        GenericCamera("Side")
    ]

#if os(visionOS)
    let defaultViewingModel = GenericViewingModel(.portal)
#else
    let defaultViewingModel = GenericViewingModel(.tabletop)
#endif

    init() {
        super.init(
            // Style and sub-style lists are empty: no scene-specific material variants
            // are assumed. The placeholder values are required by AssetModel but are
            // never displayed in the UI or sent to the server.
            styleList: [],
            style: GenericMaterial.placeholder,
            subStyleList: [],
            subStyle: GenericStyle.placeholder,
            path: [
                .cameraPrefix: "/World/Cameras/cameraViews/RIG_Main/RIG_Cameras/",
                .cameraActivate: "setActiveCamera"
            ],
            // Only the viewing mode is tracked in state. No scene-specific state
            // (environment, color, material style, visibility) is sent to the
            // Omniverse server on connect, keeping the viewer scene-neutral.
            stateDict: [
                viewingKey: .init(defaultViewingModel, serverNotifiesCompletion: true)
            ],
            actions: [],
            environments: [],   // no hardcoded environment variants
            interiorCameras: [],
            exteriorCameras: exteriorSceneCameras,
            seatCameras: [],
            switchVariantCompleteType: "switchVariantComplete",
            variantSetNameField: "variantSetName"
        )
    }

    override func supports(_ feature: Feature) -> Bool {
        switch feature {
        case .seatView:
            false
        default:
            super.supports(feature)
        }
    }

    override func onViewModel() {
        // No scene-specific actions are registered; the viewer is scene-neutral.
        actions = []
        if let configuratorViewModel {
            let portalViewing = makeViewingModel(.portal)
            if configuratorViewModel.currentViewing != portalViewing {
                configuratorViewModel.currentViewing = portalViewing
            }
        }
    }

    override public func makeViewingModel(_ mode: ViewingModel.Mode) -> ViewingModel {
        GenericViewingModel(mode)
    }
}

// MARK: - Viewing mode

public struct GenericViewingModeClientInputEvent: MessageDictionary {
    public let message: Dictionary<String, String>
    public let type = setGenericVariantEventType

    public init(_ viewing: GenericViewingModel) {
        message = [
            "primPath": "/World/Background/context",
            "variantSetName": viewingKey,
            "variantName": viewing.mode.rawValue
        ]
    }
}

public class GenericViewingModel: ViewingModel {
    public override var description: String { mode.rawValue.capitalized }
    public override var encodable: any MessageDictionary { GenericViewingModeClientInputEvent(self) }

    override public func makeViewingModel(_ mode: Mode) -> ViewingModel {
        GenericViewingModel(mode)
    }
}

// MARK: - Camera message

public struct GenericCameraClientInputEvent: MessageDictionary {
    static let cameraPrefix = "/World/Cameras/cameraViews/RIG_Main/RIG_Cameras/"
    static let setActiveCameraEventType = "setActiveCamera"

    public let message: Dictionary<String, String>
    public let type = Self.setActiveCameraEventType

    public init(_ cameraName: String) {
        message = ["cameraPath": "\(Self.cameraPrefix)\(cameraName)"]
    }
}

// MARK: - Internal style placeholders
//
// These minimal types exist only to satisfy the non-optional `style` and
// `subStyle` parameters required by AssetModel.init(). They are never added
// to `styleList` / `subStyleList`, never displayed in the UI, and never sent
// to the Omniverse server.

enum GenericMaterial: String, AssetStyle {
    public var id: String { rawValue }
    case placeholder = "placeholder"
    public var description: String { rawValue }
    public var encodable: any MessageDictionary { GenericMaterialClientInputEvent(self) }
}

struct GenericMaterialClientInputEvent: MessageDictionary {
    public let message: [String: String]
    public let type = setGenericVariantEventType
    public init(_ material: GenericMaterial) {
        message = ["variantSetName": "color", "variantName": material.rawValue]
    }
}

enum GenericStyle: String, AssetStyle {
    public var id: String { rawValue }
    case placeholder = "placeholder"
    public var description: String { rawValue }
    public var encodable: any MessageDictionary { GenericStyleClientInputEvent(self) }
}

struct GenericStyleClientInputEvent: MessageDictionary {
    public let message: Dictionary<String, String>
    public let type = setGenericVariantEventType
    public init(_ style: any AssetStyle) {
        message = ["variantSetName": "style", "variantName": style.rawValue]
    }
}
