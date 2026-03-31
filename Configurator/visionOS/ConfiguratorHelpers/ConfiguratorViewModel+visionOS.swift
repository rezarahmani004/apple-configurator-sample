// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import SwiftUI
import RealityKit

@Observable
class ConfiguratorViewModel: Placeable {
    var sessionEntity: Entity?

    // MARK: - Viewing Mode

    var currentViewing = ViewingModel(.portal) {
        willSet {
            assert(currentViewing != newValue)
        }
    }

    var viewIsLoading = true {
        willSet {
            assert(viewIsLoading != newValue)
        }
    }

    var objectVisible = true
    var objectRotated = false
    var lightIntensity: Float = 1.0

    var sceneEntity: Entity?

    // MARK: - Placement

    var placementState: PlacementManager.State = .none
    var placementPosition = simd_float3()
    var placementOrientation = simd_quatf.identity

    // MARK: - Gesture Related

    var lastLocation = vector_float3.zero
    var lastScale = Float(1)
    var lastRotation = Float.zero
    var modelRotationRadians = Float.zero
    var currentGesture = CurrentGesture.none

    // MARK: - Exact Keys from Inputs.csv

    let key_P_IT_rack = "P_IT_rack"
    let key_Altitude = "Altitude"
    let key_T_Ambient = "T_Ambient"
    let key_Fan_Speed = "Fan_ Speed"
    let key_Auto_Actions = "Auto_Actions"

    // MARK: - Simulation Inputs

    var P_IT_rack: Double = 1000
    var Altitude: Double = 0
    var T_Ambient: Double = 40
    var Fan_Speed: Double = 400
    var Auto_Actions: Bool = false

    // MARK: - Input Limits from Inputs.csv

    let min_P_IT_rack: Double = 200
    let max_P_IT_rack: Double = 1000
    let step_P_IT_rack: Double = 100

    let min_Altitude: Double = 0
    let max_Altitude: Double = 2000
    let step_Altitude: Double = 500

    let min_T_Ambient: Double = 0
    let max_T_Ambient: Double = 45
    let step_T_Ambient: Double = 5

    let min_Fan_Speed: Double = 75
    let max_Fan_Speed: Double = 500
    let step_Fan_Speed: Double = 25

    // MARK: - Defaults from Inputs.csv

    let default_P_IT_rack: Double = 1000
    let default_Altitude: Double = 0
    let default_T_Ambient: Double = 40
    let default_Fan_Speed: Double = 400
    let default_Auto_Actions: Bool = false   // "no" in CSV

    // MARK: - Simulation UI State

    var hasUnsavedSimulationChanges: Bool = false
    var simulationStatusText: String = "Ready"
    var lastSimulationAction: String = "None"
}

extension ConfiguratorViewModel {
    func wasTapped() {
        if let sessionEntity = sessionEntity {
            sessionEntity.position = placementPosition
        }
    }
}

extension ConfiguratorViewModel {
    // MARK: - Simulation Helpers

    func markSimulationInputsChanged() {
        hasUnsavedSimulationChanges = true
        simulationStatusText = "Parameters changed locally"
    }

    func resetSimulationInputsToDefaults() {
        P_IT_rack = default_P_IT_rack
        Altitude = default_Altitude
        T_Ambient = default_T_Ambient
        Fan_Speed = default_Fan_Speed
        Auto_Actions = default_Auto_Actions

        hasUnsavedSimulationChanges = true
        simulationStatusText = "Defaults restored locally"
        lastSimulationAction = "Reset Defaults"
    }

    func applySimulationInputsLocally() {
        hasUnsavedSimulationChanges = false
        simulationStatusText = "Ready to send parameters to Omniverse"
        lastSimulationAction = "Apply"
    }

    func markSteadyStateRequested() {
        simulationStatusText = "Steady-state simulation requested"
        lastSimulationAction = "Run Steady State"
    }

    func markTransientStartRequested() {
        simulationStatusText = "Transient simulation start requested"
        lastSimulationAction = "Start Transient"
    }

    func markTransientStopRequested() {
        simulationStatusText = "Transient simulation stop requested"
        lastSimulationAction = "Stop Transient"
    }
}

public extension simd_float4x4 {
    static var identity: simd_float4x4 { matrix_identity_float4x4 }
    static var zero: simd_float4x4 { simd_float4x4() }
}

public extension simd_quatf {
    static var identity: simd_quatf { .init(matrix_float4x4.identity) }
}
