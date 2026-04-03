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
        let channelCount = session?.availableMessageChannels.count ?? 0
        hasAvailableChannels = channelCount > 0
        print("[SIM CONNECT] availableChannels=\(channelCount)")
        listener?.serverMessageDispatcherDidUpdateChannels(self)
    }

    @discardableResult
    func sendMessage(_ text: String) -> Bool {
        guard let session = session,
              let firstChannelInfo = session.availableMessageChannels.first,
              let channel = session.getMessageChannel(firstChannelInfo) else {
            print("[SIM WARN] no message channel available")
            queuedMessages.append(text)
            return false
        }

        guard let data = text.data(using: .utf8) else {
            print("[SIM ERROR] message encoding failed, cannot send")
            return false
        }

        let success = channel.sendServerMessage(data)
        print(success ? "[SIM SEND] send success" : "[SIM SEND] send failed")
        return success
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
