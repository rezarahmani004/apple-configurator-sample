// SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import SwiftUI
import CloudXRKit

struct ConfigureView: View {
    @Environment(ConfiguratorAppModel.self) var configuratorAppModel
    @Environment(ConfiguratorViewModel.self) var configuratorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                headerSection
                pitRackSection
                altitudeSection
                ambientTemperatureSection
                fanSpeedSection
                autoActionsSection
                actionButtonsSection
                statusSection
            }
            .padding(24)
        }
    }
}

// MARK: - Sections
private extension ConfigureView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Simulation Parameters")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Adjust the main operating inputs here before sending them to the Omniverse simulation backend.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var pitRackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("P_IT_rack")

            HStack {
                Text("P_IT_rack")
                Spacer()
                Text("\(Int(configuratorViewModel.P_IT_rack)) kW")
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { configuratorViewModel.P_IT_rack },
                    set: { newValue in
                        configuratorViewModel.P_IT_rack = newValue
                        configuratorViewModel.markSimulationInputsChanged()
                    }
                ),
                in: configuratorViewModel.min_P_IT_rack...configuratorViewModel.max_P_IT_rack,
                step: configuratorViewModel.step_P_IT_rack
            )

            Text("Range: \(Int(configuratorViewModel.min_P_IT_rack)) to \(Int(configuratorViewModel.max_P_IT_rack)) kW   •   Step: \(Int(configuratorViewModel.step_P_IT_rack))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    var altitudeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Altitude")

            HStack {
                Text("Altitude")
                Spacer()
                Text("\(Int(configuratorViewModel.Altitude)) m")
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { configuratorViewModel.Altitude },
                    set: { newValue in
                        configuratorViewModel.Altitude = newValue
                        configuratorViewModel.markSimulationInputsChanged()
                    }
                ),
                in: configuratorViewModel.min_Altitude...configuratorViewModel.max_Altitude,
                step: configuratorViewModel.step_Altitude
            )

            Text("Range: \(Int(configuratorViewModel.min_Altitude)) to \(Int(configuratorViewModel.max_Altitude)) m   •   Step: \(Int(configuratorViewModel.step_Altitude))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    var ambientTemperatureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("T_Ambient")

            HStack {
                Text("T_Ambient")
                Spacer()
                Text("\(Int(configuratorViewModel.T_Ambient)) °C")
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { configuratorViewModel.T_Ambient },
                    set: { newValue in
                        configuratorViewModel.T_Ambient = newValue
                        configuratorViewModel.markSimulationInputsChanged()
                    }
                ),
                in: configuratorViewModel.min_T_Ambient...configuratorViewModel.max_T_Ambient,
                step: configuratorViewModel.step_T_Ambient
            )

            Text("Range: \(Int(configuratorViewModel.min_T_Ambient)) to \(Int(configuratorViewModel.max_T_Ambient)) °C   •   Step: \(Int(configuratorViewModel.step_T_Ambient))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    var fanSpeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Fan_ Speed")

            HStack {
                Text("Fan_ Speed")
                Spacer()
                Text("\(Int(configuratorViewModel.Fan_Speed)) rpm")
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: { configuratorViewModel.Fan_Speed },
                    set: { newValue in
                        configuratorViewModel.Fan_Speed = newValue
                        configuratorViewModel.markSimulationInputsChanged()
                    }
                ),
                in: configuratorViewModel.min_Fan_Speed...configuratorViewModel.max_Fan_Speed,
                step: configuratorViewModel.step_Fan_Speed
            )

            Text("Range: \(Int(configuratorViewModel.min_Fan_Speed)) to \(Int(configuratorViewModel.max_Fan_Speed)) rpm   •   Step: \(Int(configuratorViewModel.step_Fan_Speed))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    var autoActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Auto_Actions")

            Toggle(
                isOn: Binding(
                    get: { configuratorViewModel.Auto_Actions },
                    set: { newValue in
                        configuratorViewModel.Auto_Actions = newValue
                        configuratorViewModel.markSimulationInputsChanged()
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Auto_Actions")
                    Text("Checkbox input from the Omniverse input definition.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)

            Text("Allowed values: no / yes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Actions")

            HStack(spacing: 12) {
                Button("Reset Defaults") {
                    configuratorViewModel.resetSimulationInputsToDefaults()
                }
                .buttonStyle(.bordered)

                Button("Apply") {
                    configuratorAppModel.sendSimulationInputs(from: configuratorViewModel)
                    configuratorViewModel.applySimulationInputsLocally()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                Button("Run Steady State") {
                    configuratorAppModel.sendRunSteadyState()
                    configuratorViewModel.markSteadyStateRequested()
                }
                .buttonStyle(.borderedProminent)

                Button("Start Transient") {
                    configuratorAppModel.sendStartTransient()
                    configuratorViewModel.markTransientStartRequested()
                }
                .buttonStyle(.borderedProminent)

                Button("Stop Transient") {
                    configuratorAppModel.sendStopTransient()
                    configuratorViewModel.markTransientStopRequested()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Status")

            HStack {
                Text("State")
                Spacer()
                Text(configuratorViewModel.simulationStatusText)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Last Action")
                Spacer()
                Text(configuratorViewModel.lastSimulationAction)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Unsaved Changes")
                Spacer()
                Text(configuratorViewModel.hasUnsavedSimulationChanges ? "Yes" : "No")
                    .foregroundStyle(configuratorViewModel.hasUnsavedSimulationChanges ? .orange : .green)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var configuratorAppModel = ConfiguratorAppModel()
    @Previewable @State var configuratorViewModel = ConfiguratorViewModel()

    ConfigureView()
        .environment(appModel)
        .environment(configuratorAppModel)
        .environment(configuratorViewModel)
}
