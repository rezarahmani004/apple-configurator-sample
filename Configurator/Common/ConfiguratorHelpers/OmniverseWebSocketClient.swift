import Foundation

final class OmniverseWebSocketClient: NSObject {

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private var isConnected: Bool = false
    private var isConnecting: Bool = false

    private let urlString: String

    init(ip: String, port: Int) {
        self.urlString = "ws://\(ip):\(port)"
        super.init()
    }

    func connectIfNeeded() {
        if isConnected || isConnecting {
            print("⚠️ [WebSocket] Already connected or connecting")
            return
        }
        connect()
    }

    func connect() {
        guard let url = URL(string: urlString) else {
            print("❌ [WebSocket] Invalid URL: \(urlString)")
            return
        }

        if webSocketTask != nil {
            print("⚠️ [WebSocket] Existing socket detected, skipping duplicate connect")
            return
        }

        print("🔌 [WebSocket] Attempting connection to \(urlString)")
        isConnecting = true

        let session = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()
        )

        self.urlSession = session
        let task = session.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()

        listen()
    }

    func disconnect() {
        print("🔌 [WebSocket] Disconnecting")
        isConnected = false
        isConnecting = false
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession = nil
    }

    func send(json: [String: Any], completion: ((Bool) -> Void)? = nil) {
        guard let task = webSocketTask else {
            print("❌ [WebSocket] Send failed: socket not initialized")
            completion?(false)
            return
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            guard let string = String(data: data, encoding: .utf8) else {
                print("❌ [WebSocket] Failed to encode JSON as UTF-8 string")
                completion?(false)
                return
            }

            print("📤 [WebSocket] Sending:")
            print(string)

            task.send(.string(string)) { error in
                if let error = error {
                    print("❌ [WebSocket] Send failed: \(error)")
                    completion?(false)
                } else {
                    print("✅ [WebSocket] Send succeeded")
                    completion?(true)
                }
            }

        } catch {
            print("❌ [WebSocket] JSON serialization failed: \(error)")
            completion?(false)
        }
    }

    private func listen() {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print("❌ [WebSocket] Receive error: \(error)")
                self.isConnected = false
                self.isConnecting = false
                self.reconnect()

            case .success(let message):
                self.isConnected = true
                self.isConnecting = false

                switch message {
                case .string(let text):
                    print("📩 [WebSocket] Received text: \(text)")
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("📩 [WebSocket] Received data: \(text)")
                    } else {
                        print("📩 [WebSocket] Received binary data")
                    }
                @unknown default:
                    print("⚠️ [WebSocket] Received unknown message type")
                }

                self.listen()
            }
        }
    }

    private func reconnect() {
        print("🔁 [WebSocket] Reconnecting in 2 seconds...")
        webSocketTask = nil
        isConnected = false
        isConnecting = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.connectIfNeeded()
        }
    }
}

extension OmniverseWebSocketClient: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        print("✅ [WebSocket] Connected successfully")
        isConnected = true
        isConnecting = false
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        print("⚠️ [WebSocket] Closed")
        isConnected = false
        isConnecting = false
        self.webSocketTask = nil
    }
}
