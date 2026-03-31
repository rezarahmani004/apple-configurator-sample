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

// MARK: - Payload Dictionaries

public struct SetSimulationInputsMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = "setSimulationInputs"

    public init(
        P_IT_rack: Double,
        Altitude: Double,
        T_Ambient: Double,
        Fan_Speed: Double,
        Auto_Actions: Bool
    ) {
        message = [
            "P_IT_rack": String(Int(P_IT_rack)),
            "Altitude": String(Int(Altitude)),
            "T_Ambient": String(Int(T_Ambient)),
            "Fan_ Speed": String(Int(Fan_Speed)),
            "Auto_Actions": Auto_Actions ? "yes" : "no"
        ]
    }
}

public struct RunSteadyStateMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = "runSteadyState"

    public init() {
        message = [
            "command": "runSteadyState"
        ]
    }
}

public struct StartTransientMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = "startTransient"

    public init() {
        message = [
            "command": "startTransient"
        ]
    }
}

public struct StopTransientMessageDictionary: MessageDictionary {
    public let message: [String: String]
    public let type = "stopTransient"

    public init() {
        message = [
            "command": "stopTransient"
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
