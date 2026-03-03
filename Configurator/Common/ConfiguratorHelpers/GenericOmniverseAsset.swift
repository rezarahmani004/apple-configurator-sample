// SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import Foundation

/// A placeholder style used by GenericOmniverseAsset to satisfy AssetModel requirements
/// when no configurable styles are needed.
enum GenericNoStyle: String, AssetStyle {
    case placeholder = ""
    public var id: String { rawValue }
    public var description: String { "" }
    public var encodable: any MessageDictionary { BaseMessageDictionary() }
}

/// A ViewingModel for generic Omniverse streaming that does not send variant
/// selection messages to the server.
public class GenericViewingModel: ViewingModel {
    public override var description: String { mode.rawValue.capitalized }
    public override var encodable: any MessageDictionary { BaseMessageDictionary() }

    override public func makeViewingModel(_ mode: Mode) -> ViewingModel {
        GenericViewingModel(mode)
    }
}

/// A generic AssetModel for streaming any Omniverse USD file.
///
/// Unlike purse-specific assets, this model has no configurable styles,
/// sub-styles, or environments. It only sets up portal-mode viewing so
/// CloudXR content is rendered inside a portal window on visionOS.
public class GenericOmniverseAsset: AssetModel {
#if os(visionOS)
    static let defaultViewingMode: ViewingModel.Mode = .portal
#else
    static let defaultViewingMode: ViewingModel.Mode = .tabletop
#endif

    var defaultViewingModel: GenericViewingModel { GenericViewingModel(Self.defaultViewingMode) }

    init() {
        super.init(
            styleList: [],
            style: GenericNoStyle.placeholder,
            subStyleList: [],
            subStyle: GenericNoStyle.placeholder,
            path: [:],
            stateDict: [
                viewingKey: .init(GenericViewingModel(Self.defaultViewingMode), serverNotifiesCompletion: false)
            ],
            actions: [],
            environments: [],
            interiorCameras: [],
            exteriorCameras: [],
            seatCameras: [],
            switchVariantCompleteType: "",
            variantSetNameField: ""
        )
    }

    override public func makeViewingModel(_ mode: ViewingModel.Mode) -> ViewingModel {
        GenericViewingModel(mode)
    }

    override func supports(_ feature: Feature) -> Bool { false }
}
