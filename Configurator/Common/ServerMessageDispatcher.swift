import Foundation
import CloudXRKit

protocol ServerMessageListener: AnyObject {
    func serverMessageDispatcherDidUpdateChannels(_ dispatcher: ServerMessageDispatcher)
    func serverMessageDispatcher(_ dispatcher: ServerMessageDispatcher, didReceiveText text: String)
}

extension ServerMessageListener {
    func serverMessageDispatcherDidUpdateChannels(_ dispatcher: ServerMessageDispatcher) {}
    func serverMessageDispatcher(_ dispatcher: ServerMessageDispatcher, didReceiveText text: String) {}
}

final class ServerMessageDispatcher {
    weak var session: Session?
    private weak var stateManager: OmniverseStateManager?
    weak var listener: ServerMessageListener?

    private(set) var hasAvailableChannels: Bool = false
    private var queuedMessages: [String] = []
    private var isProcessingQueue = false

    func attach(_ stateManager: OmniverseStateManager) {
        self.stateManager = stateManager
        startQueuedMessageProcessingIfNeeded()
        print("ServerMessageDispatcher session attached")
        attachMessageListener()
        refreshChannelAvailability()
    }

    private func startQueuedMessageProcessingIfNeeded() {
        guard !isProcessingQueue else { return }
        isProcessingQueue = true
        print("Started queued message processing task")
    }

    private func attachMessageListener() {
        print("Attached message listener")
    }

    func refreshChannelAvailability() {
        // Conservative default for now:
        // until your real channel-availability callback is wired,
        // keep this false so nothing claims the channel is ready.
        hasAvailableChannels = false

        if hasAvailableChannels {
            print("✅ Message channel available.")
        } else {
            print("No message channels available.")
        }

        listener?.serverMessageDispatcherDidUpdateChannels(self)
    }

    @discardableResult
    func sendMessage(_ text: String) -> Bool {
        guard hasAvailableChannels else {
            print("Channel [first available] not ready - queued message")
            queuedMessages.append(text)
            return false
        }

        print("Sending raw text message to server: \(text)")
        // Hook your real CloudXR send here later
        return true
    }

    @discardableResult
    func sendMessage(_ dictionary: [String: String]) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
            guard let text = String(data: data, encoding: .utf8) else {
                print("Failed to encode [String:String] message")
                return false
            }
            return sendMessage(text)
        } catch {
            print("Failed to serialize [String:String] message: \(error)")
            return false
        }
    }

    @discardableResult
    func sendMessage(_ dictionary: [String: Any]) -> Bool {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
            guard let text = String(data: data, encoding: .utf8) else {
                print("Failed to encode [String:Any] message")
                return false
            }
            return sendMessage(text)
        } catch {
            print("Failed to serialize [String:Any] message: \(error)")
            return false
        }
    }

    @discardableResult
    func sendMessage(_ data: Data) -> Bool {
        if let text = String(data: data, encoding: .utf8) {
            return sendMessage(text)
        } else {
            print("Failed to decode Data message as UTF-8")
            return false
        }
    }

    func receiveMessage(_ text: String) {
        print("Received server message: \(text)")
        listener?.serverMessageDispatcher(self, didReceiveText: text)
    }
}
