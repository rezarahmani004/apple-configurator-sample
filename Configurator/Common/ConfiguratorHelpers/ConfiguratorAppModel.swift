// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary

import Foundation
import CloudXRKit

@Observable
class ConfiguratorAppModel {
    static var omniverseMessageDispatcher = ServerMessageDispatcher()

    private let maxSendAttempts = 24
    private let sendRetryDelay: TimeInterval = 0.25

    var session: Session? {
        get { asset.stateManager.session }
        set {
            asset.stateManager.session = newValue
            Self.omniverseMessageDispatcher.session = newValue

            if newValue != nil {
                Self.omniverseMessageDispatcher.attach(asset.stateManager)
            }

            let channelCount = newValue?.availableMessageChannels.count ?? 0
            print("[SIM CONNECT] availableChannels=\(channelCount) sessionIsNil=\(newValue == nil)")
        }
    }

    var asset: AssetModel = GenericSceneAsset()
    var gestureHelper: GestureHelper?

    // MARK: - Basic wrappers

    func desiredState(_ key: String) -> (any MessageProtocol)? {
        asset.stateManager.desiredState(key)
    }

    func isAwaitingCompletion(_ stateKey: String) -> Bool {
        asset.stateManager.isAwaitingCompletion(stateKey)
    }

    var isCloudXRReady: Bool {
        asset.stateManager.session != nil
    }

    var availableMessageChannelCount: Int {
        asset.stateManager.session?.availableMessageChannels.count ?? 0
    }

    var hasAvailableMessageChannel: Bool {
        availableMessageChannelCount > 0
    }

    private func log(_ text: String) {
        print("[ConfiguratorAppModel] \(text)")
    }

    // MARK: - Compatibility send wrapper

    func send(_ message: any MessageProtocol) {
        sendWhenMessageChannelReady(message, label: "generic")
    }

    private func sendDirectlyOverCloudXR(_ message: any MessageProtocol, label: String) {
        sendWhenMessageChannelReady(message, label: label)
    }

    // MARK: - Reliable CloudXR send

    private func sendWhenMessageChannelReady(
        _ message: any MessageProtocol,
        label: String,
        attempt: Int = 0
    ) {
        guard isCloudXRReady else {
            print("[SIM WARN] CloudXR session is nil — command not sent: \(label)")
            return
        }

        if hasAvailableMessageChannel {
            if attempt > 0 {
                print("[SIM SEND] channel became available after \(attempt) retry(s), sending: \(label)")
            }
            asset.stateManager.send(message)
            return
        }

        if attempt >= maxSendAttempts {
            print("[SIM WARN] no message channel available after \(attempt) attempts — command not sent: \(label)")
            return
        }

        if attempt == 0 {
            print("[SIM WARN] no message channel available yet, will retry: \(label)")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + sendRetryDelay) { [weak self] in
            self?.sendWhenMessageChannelReady(
                message,
                label: label,
                attempt: attempt + 1
            )
        }
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

        print("[SIM SEND] Built type=setSimulationInputs payloadKeys=[P_IT_rack, Altitude, T_Ambient, Fan_Speed, Auto_Actions, source, schemaVersion]")
        print("[SIM SEND] P_IT_rack=\(P_IT_rack) Altitude=\(Altitude) T_Ambient=\(T_Ambient) Fan_Speed=\(Fan_Speed) Auto_Actions=\(Auto_Actions)")

        sendDirectlyOverCloudXR(message, label: "setSimulationInputs")
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
        let message = RunSteadyStateMessage()
        print("[SIM SEND] Built type=runSteadyState")
        sendDirectlyOverCloudXR(message, label: "runSteadyState")
    }

    func sendStartTransient() {
        let message = StartTransientMessage()
        print("[SIM SEND] Built type=startTransient")
        sendDirectlyOverCloudXR(message, label: "startTransient")
    }

    func sendStopTransient() {
        let message = StopTransientMessage()
        print("[SIM SEND] Built type=stopTransient")
        sendDirectlyOverCloudXR(message, label: "stopTransient")
    }

    // MARK: - Setup

    func setup(
        application: Application,
        configuratorViewModel: ConfiguratorViewModel,
        session: Session
    ) {
        switch application {
        case .generic_scene:
            asset = GenericSceneAsset()
        }

        if let assetConfiguratorViewModel = asset.configuratorViewModel {
            assetConfiguratorViewModel.lightIntensity =
                (asset.lightnessRange.upperBound - asset.lightnessRange.lowerBound) / 2.0
            assetConfiguratorViewModel.currentViewing = asset.makeViewingModel(.portal)
        }

        asset.configuratorViewModel = configuratorViewModel

        gestureHelper = GestureHelper(
            configuratorViewModel: configuratorViewModel,
            configuratorAppModel: self
        )

        self.session = session

        print("[SIM CONNECT] session created, CloudXRReady=\(isCloudXRReady) availableChannels=\(availableMessageChannelCount)")
    }
}
