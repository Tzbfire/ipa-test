import Foundation
import Network

final class PortForwardManager {
    static let shared = PortForwardManager()

    private final class Entry {
        let localPort: Int
        let targetPort: Int
        let host: String
        var listener: NWListener?

        init(localPort: Int, targetPort: Int, host: String, listener: NWListener?) {
            self.localPort = localPort
            self.targetPort = targetPort
            self.host = host
            self.listener = listener
        }
    }

    private var entries: [Int: Entry] = [:]
    private let queue = DispatchQueue(label: "clawbench.port.forward.manager")

    private init() {}

    func register(localPort: Int, targetPort: Int, host: String) {
        unregister(localPort: localPort)
        let targetHost = resolvedHost(host)
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(localPort)) else { return }

        do {
            let listener = try NWListener(using: .tcp, on: nwPort)
            let entry = Entry(localPort: localPort, targetPort: targetPort, host: targetHost, listener: listener)
            entries[localPort] = entry

            listener.newConnectionHandler = { [weak self] client in
                self?.handle(client: client, targetHost: targetHost, targetPort: targetPort)
            }
            listener.stateUpdateHandler = { state in
                switch state {
                case .failed, .cancelled:
                    break
                default:
                    break
                }
            }
            listener.start(queue: queue)
        } catch {
            // If binding localPort fails, keep metadata so the UI can still continue gracefully.
            entries[localPort] = Entry(localPort: localPort, targetPort: targetPort, host: targetHost, listener: nil)
        }
    }

    func unregister(localPort: Int) {
        if let entry = entries.removeValue(forKey: localPort) {
            entry.listener?.cancel()
        }
    }

    func stopAll() {
        for entry in entries.values {
            entry.listener?.cancel()
        }
        entries.removeAll()
    }

    func isReachable(port: Int) -> Bool {
        return entries[port] != nil
    }

    func urlFor(localPort: Int, protocolValue: String) -> String {
        let scheme = protocolValue == "https" ? "https" : "http"
        return "\(scheme)://127.0.0.1:\(localPort)"
    }

    private func resolvedHost(_ host: String) -> String {
        let trimmed = host.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if let serverURL = UserDefaults.standard.string(forKey: "clawbench.serverUrl"),
           let url = URL(string: serverURL),
           let urlHost = url.host {
            return urlHost
        }
        return "127.0.0.1"
    }

    private func handle(client: NWConnection, targetHost: String, targetPort: Int) {
        guard let remotePort = NWEndpoint.Port(rawValue: UInt16(targetPort)) else {
            client.cancel()
            return
        }
        let remote = NWConnection(host: NWEndpoint.Host(targetHost), port: remotePort, using: .tcp)
        client.start(queue: queue)
        remote.start(queue: queue)
        pipe(from: client, to: remote)
        pipe(from: remote, to: client)
    }

    private func pipe(from source: NWConnection, to target: NWConnection) {
        source.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                target.send(content: data, completion: .contentProcessed { sendError in
                    if sendError != nil {
                        source.cancel()
                        target.cancel()
                        return
                    }
                    if isComplete || error != nil {
                        source.cancel()
                        target.cancel()
                    } else {
                        self?.pipe(from: source, to: target)
                    }
                })
            } else {
                source.cancel()
                target.cancel()
            }
        }
    }
}
