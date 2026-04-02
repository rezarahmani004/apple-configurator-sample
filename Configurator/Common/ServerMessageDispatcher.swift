import Foundation
import CloudXRKit
import os.log

protocol ServerMessageListener: AnyObject {
    func serverMessageDispatcherDidUpdateChannels(_ dispatcher: ServerMessageDispatcher)
    func serverMessageDispatcher(_ dispatcher: ServerMessageDispatcher, didReceiveText text: String)
}

extension ServerMessageListener {
    func serverMessageDispatcherDidUpdateChannels(_ dispatcher: ServerMessageDispatcher) {}
    func serverMessageDispatcher(_ dispatcher: ServerMessageDispatcher, didReceiveText text: String) {}
}

final class ServerMessageDispatcher {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.nvidia.configurator",
        category: "ServerMessageDispatcher"
    )

    weak var session: Session?
    private weak var stateManager: OmniverseStateManager?
    weak var listener: ServerMessageListener?

    private(set) var hasAvailableChannels: Bool = false
    private var selectedChannel: MessageChannel?
    private var queuedMessages: [Data] = []

    func attach(_ stateManager: OmniverseStateManager) {
        self.stateManager = stateManager
        Self.logger.info("[SIM] ServerMessageDispatcher: session attached")
        refreshChannelAvailability()
    }

    func refreshChannelAvailability() {
        guard let session = session else {
            if hasAvailableChannels {
                Self.logger.warning("[SIM WARN] ServerMessageDispatcher: session lost — channel cleared")
            }
            hasAvailableChannels = false
            selectedChannel = nil
            listener?.serverMessageDispatcherDidUpdateChannels(self)
            return
        }

        let channels = session.availableMessageChannels
        guard let firstInfo = channels.first,
              let channel = session.getMessageChannel(firstInfo) else {
            if hasAvailableChannels {
                Self.logger.warning("[SIM WARN] ServerMessageDispatcher: channels gone (count=\(channels.count))")
            }
            hasAvailableChannels = false
            selectedChannel = nil
            listener?.serverMessageDispatcherDidUpdateChannels(self)
            return
        }

        let wasReady = hasAvailableChannels
        selectedChannel = channel
        hasAvailableChannels = true
        if !wasReady {
            Self.logger.info("[SIM] ServerMessageDispatcher: channel selected/ready. availableChannels=\(channels.count)")
            flushQueuedMessages()
        }
        listener?.serverMessageDispatcherDidUpdateChannels(self)
    }

    private func flushQueuedMessages() {
        guard !queuedMessages.isEmpty else { return }
        Self.logger.info("[SIM] Flushing \(self.queuedMessages.count) queued message(s)")
        let pending = queuedMessages
        queuedMessages.removeAll()
        for data in pending {
            _ = sendDataDirect(data)
        }
    }

    @discardableResult
    private func sendDataDirect(_ data: Data) -> Bool {
        guard let channel = selectedChannel else {
            Self.logger.error("[SIM ERROR] sendDataDirect: no selected channel")
            return false
        }
        let success = channel.sendServerMessage(data)
        if !success {
            Self.logger.error("[SIM ERROR] channel.sendServerMessage failed (\(data.count) bytes)")
        }
        return success
    }

    @discardableResult
    func sendMessage(_ text: String) -> Bool {
        guard let data = text.data(using: .utf8) else {
            Self.logger.error("[SIM ERROR] Failed to encode message as UTF-8")
            return false
        }
        return sendMessage(data)
    }

    @discardableResult
    func sendMessage(_ dictionary: [String: String]) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
            return sendMessage(data)
        } catch {
            Self.logger.error("[SIM ERROR] Failed to serialize [String:String] message: \(error)")
            return false
        }
    }

    @discardableResult
    func sendMessage(_ dictionary: [String: Any]) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
            return sendMessage(data)
        } catch {
            Self.logger.error("[SIM ERROR] Failed to serialize [String:Any] message: \(error)")
            return false
        }
    }

    @discardableResult
    func sendMessage(_ data: Data) -> Bool {
        guard hasAvailableChannels else {
            Self.logger.warning("[SIM WARN] channel not ready — queuing message (\(self.queuedMessages.count + 1) in queue)")
            queuedMessages.append(data)
            return false
        }
        return sendDataDirect(data)
    }

    func receiveMessage(_ text: String) {
        Self.logger.info("[SIM RECV] incoming server message: \(text)")
        listener?.serverMessageDispatcher(self, didReceiveText: text)
    }
}
