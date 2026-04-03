// SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import Foundation

// MARK: - Shared constants

enum SimulationMessageType {
    static let setSimulationInputs = "setSimulationInputs"
    static let runSteadyState = "runSteadyState"
    static let startTransient = "startTransient"
    static let stopTransient = "stopTransient"
}

enum SimulationMessageKey {
    static let source = "source"
    static let schemaVersion = "schemaVersion"

    static let pItRack = "P_IT_rack"
    static let altitude = "Altitude"
    static let tAmbient = "T_Ambient"
    static let fanSpeed = "Fan_Speed"
    static let autoActions = "Auto_Actions"
}

// MARK: - CloudXR / Kit Message Bus Dictionaries
//
// IMPORTANT:
// CloudXR 6 / Kit message bus expects:
// {
//   "type": "...",
//   "payload": { ... }
// }
//
// So the payload dictionary must ONLY contain the payload fields.
// The event name itself is provided separately by `type`.

public struct SetSimulationInputsMessageDictionary: MessageDictionary {
    public let type = SimulationMessageType.setSimulationInputs

    // Stored as typed values so the custom encoder outputs correct JSON types
    // (JSON numbers for scalars, JSON boolean for Auto_Actions).
    private let pItRack: Double
    private let altitude: Double
    private let tAmbient: Double
    private let fanSpeed: Double
    private let autoActions: Bool

    // MessageDictionary requirement – used for logging only.
    // This is intentionally a simplified [String: String] representation and
    // is not used for JSON encoding. The authoritative wire format is produced
    // by encode(to:) below, which outputs proper JSON numbers and a boolean.
    public var message: [String: String] {
        [
            SimulationMessageKey.source: "visionOS",
            SimulationMessageKey.schemaVersion: "1",
            SimulationMessageKey.pItRack: String(pItRack),
            SimulationMessageKey.altitude: String(altitude),
            SimulationMessageKey.tAmbient: String(tAmbient),
            SimulationMessageKey.fanSpeed: String(fanSpeed),
            SimulationMessageKey.autoActions: String(autoActions)
        ]
    }

    public init(
        P_IT_rack: Double,
        Altitude: Double,
        T_Ambient: Double,
        Fan_Speed: Double,
        Auto_Actions: Bool
    ) {
        pItRack = P_IT_rack
        altitude = Altitude
        tAmbient = T_Ambient
        fanSpeed = Fan_Speed
        autoActions = Auto_Actions
    }

    // Custom encoder: produces {"type":"…","payload":{"P_IT_rack":…, …}}
    // with proper JSON numbers and a boolean, as required by the Kit message bus.
    public func encode(to encoder: Encoder) throws {
        var outer = encoder.container(keyedBy: OuterKey.self)
        try outer.encode(type, forKey: .type)
        var payload = outer.nestedContainer(keyedBy: PayloadKey.self, forKey: .payload)
        try payload.encode("visionOS", forKey: .source)
        try payload.encode("1", forKey: .schemaVersion)
        try payload.encode(pItRack, forKey: .pItRack)
        try payload.encode(altitude, forKey: .altitude)
        try payload.encode(tAmbient, forKey: .tAmbient)
        try payload.encode(fanSpeed, forKey: .fanSpeed)
        try payload.encode(autoActions, forKey: .autoActions)
    }

    private enum OuterKey: String, CodingKey {
        case type, payload
    }

    private enum PayloadKey: String, CodingKey {
        case source, schemaVersion
        case pItRack = "P_IT_rack"
        case altitude = "Altitude"
        case tAmbient = "T_Ambient"
        case fanSpeed = "Fan_Speed"
        case autoActions = "Auto_Actions"
    }
}

public struct RunSteadyStateMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = SimulationMessageType.runSteadyState

    private enum CodingKeys: String, CodingKey {
        case message = "payload"
        case type
    }

    public init() {
        message = [
            SimulationMessageKey.source: "visionOS",
            SimulationMessageKey.schemaVersion: "1"
        ]
    }
}

public struct StartTransientMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = SimulationMessageType.startTransient

    private enum CodingKeys: String, CodingKey {
        case message = "payload"
        case type
    }

    public init() {
        message = [
            SimulationMessageKey.source: "visionOS",
            SimulationMessageKey.schemaVersion: "1"
        ]
    }
}

public struct StopTransientMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = SimulationMessageType.stopTransient

    private enum CodingKeys: String, CodingKey {
        case message = "payload"
        case type
    }

    public init() {
        message = [
            SimulationMessageKey.source: "visionOS",
            SimulationMessageKey.schemaVersion: "1"
        ]
    }
}

// MARK: - MessageProtocol wrappers

public struct SetSimulationInputsMessage: MessageProtocol, Equatable {
    public let P_IT_rack: Double
    public let Altitude: Double
    public let T_Ambient: Double
    public let Fan_Speed: Double
    public let Auto_Actions: Bool

    public init(
        P_IT_rack: Double,
        Altitude: Double,
        T_Ambient: Double,
        Fan_Speed: Double,
        Auto_Actions: Bool
    ) {
        self.P_IT_rack = P_IT_rack
        self.Altitude = Altitude
        self.T_Ambient = T_Ambient
        self.Fan_Speed = Fan_Speed
        self.Auto_Actions = Auto_Actions
    }

    public var encodable: any MessageDictionary {
        SetSimulationInputsMessageDictionary(
            P_IT_rack: P_IT_rack,
            Altitude: Altitude,
            T_Ambient: T_Ambient,
            Fan_Speed: Fan_Speed,
            Auto_Actions: Auto_Actions
        )
    }
}

public struct RunSteadyStateMessage: MessageProtocol, Equatable {
    public init() {}

    public var encodable: any MessageDictionary {
        RunSteadyStateMessageDictionary()
    }
}

public struct StartTransientMessage: MessageProtocol, Equatable {
    public init() {}

    public var encodable: any MessageDictionary {
        StartTransientMessageDictionary()
    }
}

public struct StopTransientMessage: MessageProtocol, Equatable {
    public init() {}

    public var encodable: any MessageDictionary {
        StopTransientMessageDictionary()
    }
}
