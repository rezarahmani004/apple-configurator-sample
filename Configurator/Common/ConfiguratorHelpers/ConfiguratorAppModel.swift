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
import CloudXRKit

@Observable
class ConfiguratorAppModel {
    static var omniverseMessageDispatcher = ServerMessageDispatcher()

    var session: Session? {
        get { asset.stateManager.session }
        set {
            asset.stateManager.session = newValue
            Self.omniverseMessageDispatcher.session = newValue
            Self.omniverseMessageDispatcher.attach(asset.stateManager)
        }
    }

    var asset: AssetModel = GenericSceneAsset()

    // simplifying wrapper methods for asset.stateManager; ideally nobody needs to know about
    // OmniverseStateManager

    func desiredState(_ key: String) -> (any MessageProtocol)? {
        asset.stateManager.desiredState(key)
    }

    func isAwaitingCompletion(_ stateKey: String) -> Bool {
        asset.stateManager.isAwaitingCompletion(stateKey)
    }

    func send(_ message: any MessageProtocol) {
        asset.stateManager.send(message)
    }

    // MARK: - Simulation Messaging Helpers

    func sendSimulationInputs(
        P_IT_rack: Double,
        Altitude: Double,
        T_Ambient: Double,
        Fan_Speed: Double,
        Auto_Actions: Bool
    ) {
        let message = SetSimulationInputsMessage(
            P_IT_rack: P_IT_rack,
            Altitude: Altitude,
            T_Ambient: T_Ambient,
            Fan_Speed: Fan_Speed,
            Auto_Actions: Auto_Actions
        )
        send(message)
    }

    func sendSimulationInputs(from configuratorViewModel: ConfiguratorViewModel) {
        sendSimulationInputs(
            P_IT_rack: configuratorViewModel.P_IT_rack,
            Altitude: configuratorViewModel.Altitude,
            T_Ambient: configuratorViewModel.T_Ambient,
            Fan_Speed: configuratorViewModel.Fan_Speed,
            Auto_Actions: configuratorViewModel.Auto_Actions
        )
    }

    func sendRunSteadyState() {
        send(RunSteadyStateMessage())
    }

    func sendStartTransient() {
        send(StartTransientMessage())
    }

    func sendStopTransient() {
        send(StopTransientMessage())
    }

    var gestureHelper: GestureHelper?

    func setup(application: Application, configuratorViewModel: ConfiguratorViewModel, session: Session) {
        switch application {

        case Application.generic_scene:
            asset = GenericSceneAsset()
        default:
            fatalError("Unknown application type")
        }

        if let configuratorViewModel = asset.configuratorViewModel {
            configuratorViewModel.lightIntensity = (asset.lightnessRange.upperBound - asset.lightnessRange.lowerBound) / 2.0
            configuratorViewModel.currentViewing = asset.makeViewingModel(.portal)
        }
        asset.configuratorViewModel = configuratorViewModel

        gestureHelper = GestureHelper(
            configuratorViewModel: configuratorViewModel,
            configuratorAppModel: self
        )

        self.session = session
    }
}
