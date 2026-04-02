// SPDX-FileCopyrightText: Copyright (c) 2023-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

public protocol MessageDictionary: Encodable, Equatable {
    associatedtype Parameter
    var message: [String: Parameter] { get }
    var type: String { get }

    /// Encodes this message in CloudXR 6 / Kit message bus format:
    /// `{ "type": "...", "payload": { ... } }`
    /// String-encoded numbers and booleans are coerced to their native JSON types.
    func cloudXRData() -> Data?
}

extension MessageDictionary {
    public func cloudXRData() -> Data? {
        var payload: [String: Any] = [:]
        for (key, value) in message {
            let str = "\(value)"
            if let d = Double(str) {
                payload[key] = d
            } else if str == "true" {
                payload[key] = true
            } else if str == "false" {
                payload[key] = false
            } else {
                payload[key] = str
            }
        }
        let wrapper: [String: Any] = ["type": type, "payload": payload]
        return try? JSONSerialization.data(withJSONObject: wrapper)
    }
}

public struct BaseMessageDictionary: MessageDictionary {
    public var message: [String: String] = [:]
    public var type = ""
}

/// Protocol to send messages to a CloudXR session via the OmniverseStateManager.
public protocol MessageProtocol {
    /// The encodable object being sent to the session's sendServerMessage method after encoding
    var encodable: any MessageDictionary { get }

    func isEqualTo(_ other: MessageProtocol?) -> Bool
}

extension MessageProtocol where Self: Equatable {
    public func isEqualTo(_ other: MessageProtocol?) -> Bool {
        guard let otherX = other as? Self else { return false }
        return self == otherX
    }
}
