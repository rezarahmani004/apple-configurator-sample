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

let setGenericVariantEventType = "setVariantSelection"

class GenericCamera: AssetCamera {
    init(_ ovName: String = "") {
        super.init(
            ovName: ovName,
            description: ovName.replacingOccurrences(of: "_", with: " "),
            encodable: GenericCameraClientInputEvent(ovName)
        )
    }
}

public class GenericSceneAsset: AssetModel {
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
            styleList: GenericMaterial.allCases,
            style: GenericMaterial.Red,
            subStyleList: GenericStyle.allCases,
            subStyle: GenericStyle.Smooth,
            path: [
                .cameraPrefix: "/World/Cameras/cameraViews/RIG_Main/RIG_Cameras/",
                .cameraActivate: "setActiveCamera"
            ],
            stateDict: [
                "color": .init(GenericMaterial.Red),
                "style": .init(GenericStyle.Smooth),
                "objectVisibility": .init(GenericObjectVisibility.visible),
                "environment": .init(GenericEnvironment.Studio),
                viewingKey: .init(GenericViewingModel(.portal), serverNotifiesCompletion: true)
            ],
            actions: [],
            environments: GenericEnvironment.allCases,
            interiorCameras: [],
            exteriorCameras: exteriorSceneCameras,
            seatCameras: [],
            switchVariantCompleteType: "switchVariantComplete",
            variantSetNameField: "variantSetName"
        )
        lightnessRange = 0.0...2.0
        lightingKey = "lightSlider"
        let midLighting = (lightnessRange.upperBound - lightnessRange.lowerBound) / 2.0
        stateDict[lightingKey] = .init(LightSlider(midLighting, asset: self))
    }

    override func supports(_ feature: Feature) -> Bool {
        switch feature {
        case .rotation:
            true
        case .seatView:
            false
        default:
            super.supports(feature)
        }
    }

    override func onViewModel() {
        if let configuratorViewModel {
            actions = [
                GenericObjectVisibleAction(configuratorViewModel: configuratorViewModel, asset: self),
                GenericObjectRotateAction(configuratorViewModel: configuratorViewModel, asset: self),
                GenericPlacementAction(configuratorViewModel: configuratorViewModel, asset: self)
            ]
            configuratorViewModel.lightIntensity = (lightnessRange.upperBound - lightnessRange.lowerBound) / 2.0
            let portalViewing = makeViewingModel(.portal)
            if configuratorViewModel.currentViewing != portalViewing {
                configuratorViewModel.currentViewing = portalViewing
            }
        }
    }

    override public func syncPortalBrightness() {
        guard let configuratorViewModel else { return }
        self[lightingKey] = LightSlider(configuratorViewModel.lightIntensity, asset: self)
    }

    override public func makeViewingModel(_ mode: ViewingModel.Mode) -> ViewingModel {
        GenericViewingModel(mode)
    }
}

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

public enum GenericMaterial: String, AssetStyle {
    public var id: String { rawValue }

    case Red
    case Blue
    case Green
    case White

    public var description: String {
        switch self {
        case .Red:
            "Red"
        case .Blue:
            "Blue"
        case .Green:
            "Green"
        case .White:
            "White"
        }
    }

    public var encodable: any MessageDictionary { GenericMaterialClientInputEvent(self) }
}

public struct GenericMaterialClientInputEvent: MessageDictionary {
    public let message: [String: String]
    public let type = setGenericVariantEventType

    public init(_ material: GenericMaterial) {
        message = [
            "variantSetName": "color",
            "variantName": material.rawValue
        ]
    }
}

public enum GenericStyle: String, AssetStyle {
    public var id: String { rawValue }

    case Smooth
    case Matte

    public var description: String {
        switch self {
        case .Smooth:
            "Smooth"
        case .Matte:
            "Matte"
        }
    }

    public var encodable: any MessageDictionary {
        GenericStyleClientInputEvent(self)
    }
}

public struct GenericStyleClientInputEvent: MessageDictionary {
    public let message: Dictionary<String, String>
    public let type = setGenericVariantEventType

    public init(_ style: any AssetStyle) {
        message = [
            "variantSetName": "style",
            "variantName": style.rawValue
        ]
    }
}

public class GenericObjectVisibleAction: AssetAction {
    init(configuratorViewModel: ConfiguratorViewModel, asset: AssetModel) {
        super.init(
            asset: asset,
            configuratorViewModel: configuratorViewModel,
            label: "Visibility",
            onText: "On",
            offText: "Off",
            shouldToggleView: true,
            isOn: configuratorViewModel.objectVisible,
            stateName: "objectVisibility",
            enableEvent: GenericObjectVisibility.visible,
            disableEvent: GenericObjectVisibility.hidden,
            textCondition: { _ in configuratorViewModel.objectVisible },
            helpText: {
                "Toggle visibility of the object"
            }
        )
    }
}

public class GenericObjectRotateAction: AssetAction {
    init(configuratorViewModel: ConfiguratorViewModel, asset: AssetModel) {
        super.init(
            asset: asset,
            configuratorViewModel: configuratorViewModel,
            label: "Rotate",
            onText: "On",
            offText: "Off",
            shouldToggleView: false,
            isOn: configuratorViewModel.objectRotated,
            helpText: {
                "Rotate the object 180°"
            }
        )
    }

    override func toggle(_ isOn: Bool) {
        if isOn {
            asset.stateManager.send(GenericObjectRotationStates.rotateCCW)
        } else {
            asset.stateManager.send(GenericObjectRotationStates.rotateCW)
        }
        configuratorViewModel.objectRotated = isOn
    }
}

public class GenericPlacementAction: AssetAction {
    static let placementHelp = "Place model on a horizontal surface"
    static let placementPortalHelp = "Placement only available in tabletop mode"
    static let placementPlacingHelp = "Currently placing"
    static let placementNotInSimulator = "Cannot place in simulator"

#if targetEnvironment(simulator)
    static let isSimulator = true
#else
    static let isSimulator = false
#endif

    init(configuratorViewModel: ConfiguratorViewModel, asset: AssetModel) {
        super.init(
            asset: asset,
            configuratorViewModel: configuratorViewModel,
            label: "Place",
            shouldToggleView: false,
            isDisabled: {
                configuratorViewModel.isPlacing || configuratorViewModel.currentViewing.mode == .portal || Self.isSimulator
            },
            helpText: {
                if Self.isSimulator {
                    Self.placementNotInSimulator
                } else if configuratorViewModel.currentViewing.mode == .portal {
                    Self.placementPortalHelp
                } else if configuratorViewModel.isPlacing {
                    Self.placementPlacingHelp
                } else {
                    Self.placementHelp
                }
            }
        )
    }

    override func toggle(_ isOn: Bool) {
        configuratorViewModel.placementState = .started
    }
}

public struct GenericEnvironmentClientInputEvent: MessageDictionary {
    public let message: [String: String]
    public let type = setGenericVariantEventType

    public init(_ env: GenericEnvironment) {
        message = [
            "variantSetName": "environment",
            "variantName": env.rawValue
        ]
    }
}

public enum GenericEnvironment: String, AssetEnvironment {
    case Studio = "Studio"
    case Gallery = "Gallery"
    case Outdoor = "Outdoor"

    public var description: String { rawValue }
    public var isDisabled: Bool { GenericEnvironment.disabled.contains(self) }
    public var isHidden: Bool { GenericEnvironment.hidden.contains(self) }
    public var supportsLighting: Bool { GenericEnvironment.lightable.contains(self) }
    static var disabled: [GenericEnvironment] = []
    static var hidden: [GenericEnvironment] = []
    static var lightable: [GenericEnvironment] = [.Studio, .Gallery, .Outdoor]

    public var encodable: any MessageDictionary { GenericEnvironmentClientInputEvent(self) }
}

public struct GenericCameraClientInputEvent: MessageDictionary {
    static let cameraPrefix = "/World/Cameras/cameraViews/RIG_Main/RIG_Cameras/"
    static let setActiveCameraEventType = "setActiveCamera"

    public let message: Dictionary<String, String>
    public let type = Self.setActiveCameraEventType

    public init(_ cameraName: String) {
        message = ["cameraPath": "\(Self.cameraPrefix)\(cameraName)"]
    }
}

public struct GenericObjectVisibilityClientInputEvent: MessageDictionary {
    public let message: Dictionary<String, String>
    public let type = setGenericVariantEventType

    public init(_ mode: GenericObjectVisibility) {
        message = [
            "variantSetName": "visibility",
            "variantName": mode.rawValue
        ]
    }
}

public enum GenericObjectVisibility: String, MessageProtocol {
    case visible = "Visible"
    case hidden = "Hidden"

    public var encodable: any MessageDictionary { GenericObjectVisibilityClientInputEvent(self) }
}

public struct GenericObjectAnimationClientInputEvent: MessageDictionary {
    public let message: Dictionary<String, String>
    public let type = "setObjectRotation"

    public init(_ animation: String) {
        message = [
            "animationName": animation
        ]
    }
}

public enum GenericObjectRotationStates: String, MessageProtocol {
    case rotateCW = "RotateCW"
    case rotateCCW = "RotateCCW"

    public var encodable: any MessageDictionary { GenericObjectAnimationClientInputEvent(self.rawValue) }
}
