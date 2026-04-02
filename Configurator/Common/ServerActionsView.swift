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
import os.log

class IncomingMessageListener {
    var messageCounter = 0
    var onMessageHandler = { (_ message: String) -> Void in }

    func onMessageReceived(message: Data) {
        messageCounter += 1
        onMessageHandler("Message \(messageCounter): " + String(decoding: message, as: UTF8.self))
    }
}

struct ServerActionsView: View {
    static var logger = Logger()

    @Environment(AppModel.self) var appModel

    @State private var lastMessageSent: String = ""
    @State private var lastMessageReceived: String = ""

    @Binding var currentChannelSelection: ChannelInfo?
    @Binding var currentChannel: MessageChannel?

    var messageDispatcher: ServerMessageDispatcher
    @State private var incomingMessageListener = IncomingMessageListener()

    // MARK: - CloudXR JSON builder

    private func buildMessage(type: String, payload: [String: Any] = [:]) -> String? {
        let message: [String: Any] = [
            "type": type,
            "payload": payload
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: message, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            Self.logger.error("Failed to serialize JSON message for type: \(type)")
            return nil
        }

        return jsonString
    }

    // MARK: - Channel helpers

    private var hasSelectedChannel: Bool {
        currentChannelSelection != nil
    }

    private var selectedChannelStatusText: String {
        if let channel = currentChannel {
            return String(describing: channel.status)
        }
        return "N/A"
    }

    private func autoSelectFirstAvailableChannel(from session: Session) {
        guard currentChannelSelection == nil else { return }
        guard let firstChannelInfo = session.availableMessageChannels.first else { return }
        guard let firstChannel = session.getMessageChannel(firstChannelInfo) else { return }

        currentChannelSelection = firstChannelInfo
        currentChannel = firstChannel
    }

    // MARK: - Send helpers

    private func sendMessage(message: String) {
        guard hasSelectedChannel else {
            Self.logger.warning("No channel selected")
            lastMessageSent = "Error - no channel selected"
            return
        }

        guard let messageData = message.data(using: .utf8) else {
            Self.logger.warning("String message could not be converted to data")
            lastMessageSent = "Error - invalid message encoding"
            return
        }

        guard let channel = currentChannel else {
            Self.logger.warning("No current channel available for send")
            lastMessageSent = "Error - current channel unavailable"
            return
        }

        if channel.sendServerMessage(messageData) {
            lastMessageSent = message
            Self.logger.info("Sent CloudXR message successfully")
        } else {
            Self.logger.warning("Failed to send message via current channel")
            lastMessageSent = "Error - failed to send"
        }
    }

    private func sendStructuredMessage(type: String, payload: [String: Any] = [:]) {
        guard let json = buildMessage(type: type, payload: payload) else {
            lastMessageSent = "Error - failed to build JSON"
            return
        }

        sendMessage(message: json)
    }

    // MARK: - Test actions aligned with Omniverse extension

    private func sendSetSimulationInputsTest() {
        sendStructuredMessage(
            type: "setSimulationInputs",
            payload: [
                "P_IT_rack": 12000.0,
                "Altitude": 500.0,
                "T_Ambient": 298.0,
                "Fan_Speed": 0.70,
                "Auto_Actions": true,
                "source": "visionOS",
                "schemaVersion": "1"
            ]
        )
    }

    private func sendRunSteadyStateTest() {
        sendStructuredMessage(
            type: "runSteadyState",
            payload: [
                "source": "visionOS",
                "schemaVersion": "1"
            ]
        )
    }

    private func sendStartTransientTest() {
        sendStructuredMessage(
            type: "startTransient",
            payload: [
                "source": "visionOS",
                "schemaVersion": "1"
            ]
        )
    }

    private func sendStopTransientTest() {
        sendStructuredMessage(
            type: "stopTransient",
            payload: [
                "source": "visionOS",
                "schemaVersion": "1"
            ]
        )
    }

    // MARK: - View

    var body: some View {
        Form {
            VStack(spacing: 16) {
                if let session = appModel.session {
                    Picker("Channels", selection: $currentChannelSelection) {
                        ForEach(session.availableMessageChannels, id: \.self) { channelInfo in
                            Text("Channel [\(channelInfo.uuid.map { String($0) }.joined(separator: ","))]")
                                .tag(channelInfo as ChannelInfo?)
                        }
                        Text("None").tag(nil as ChannelInfo?)
                    }
                    .pickerStyle(.menu)
                    .id(session.availableMessageChannels)
                    .onChange(of: currentChannelSelection) {
                        currentChannel = nil

                        guard let selectedChannel = currentChannelSelection else {
                            return
                        }

                        guard let channel = session.getMessageChannel(selectedChannel) else {
                            return
                        }

                        currentChannel = channel
                    }
                    .onChange(of: session.availableMessageChannels) {
                        if let selectedChannel = currentChannelSelection,
                           !session.availableMessageChannels.contains(selectedChannel) {
                            currentChannelSelection = nil
                            currentChannel = nil
                        }

                        autoSelectFirstAvailableChannel(from: session)
                    }

                    Text("Status: \(selectedChannelStatusText)")
                    Text("Available channels: \(session.availableMessageChannels.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No CloudXR session")
                        .foregroundStyle(.red)
                }

                Divider()

                VStack(spacing: 12) {
                    Text("Omniverse / Flownex Test Actions")
                        .font(.headline)

                    Button("Send setSimulationInputs") {
                        sendSetSimulationInputsTest()
                    }
                    .disabled(!hasSelectedChannel)
                    .buttonStyle(.borderedProminent)

                    Button("Send runSteadyState") {
                        sendRunSteadyStateTest()
                    }
                    .disabled(!hasSelectedChannel)
                    .buttonStyle(.borderedProminent)

                    Button("Send startTransient") {
                        sendStartTransientTest()
                    }
                    .disabled(!hasSelectedChannel)
                    .buttonStyle(.borderedProminent)

                    Button("Send stopTransient") {
                        sendStopTransientTest()
                    }
                    .disabled(!hasSelectedChannel)
                    .buttonStyle(.borderedProminent)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last message sent:")
                    Divider()
                    Text(lastMessageSent.isEmpty ? "None" : lastMessageSent)
                        .textSelection(.enabled)
                    Spacer()
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last message received:")
                    Divider()
                    Text(lastMessageReceived.isEmpty ? "None" : lastMessageReceived)
                        .textSelection(.enabled)
                    Spacer()
                }
            }
        }
        .onAppear {
            guard let session = appModel.session else {
                Self.logger.warning("Cannot use ServerActionsView before initialization")
                return
            }

            autoSelectFirstAvailableChannel(from: session)

            incomingMessageListener.onMessageHandler = { [self] message in
                lastMessageReceived = message
            }
        }
        .onDisappear {
            // No dispatcher detach call here because the current dispatcher API
            // in this project does not expose a detach(...) method.
        }
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var selection: ChannelInfo? = nil
    @Previewable @State var channel: MessageChannel? = nil
    @Previewable @State var dispatcher = ServerMessageDispatcher()

    ServerActionsView(
        currentChannelSelection: $selection,
        currentChannel: $channel,
        messageDispatcher: dispatcher
    )
    .environment(appModel)
}
