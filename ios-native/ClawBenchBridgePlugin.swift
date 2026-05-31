import Foundation
import Capacitor

@objc(ClawBenchBridgePlugin)
public class ClawBenchBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "ClawBenchBridgePlugin"
    public let jsName = "ClawBenchBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isNativeApp", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getPlatform", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "testPortReachable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "addForwardedPort", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeForwardedPort", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "stopBackgroundService", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reconnectTunnel", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openInBrowser", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "openInSandbox", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "downloadFile", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "showServerDialog", returnType: CAPPluginReturnPromise)
    ]

    @objc func isNativeApp(_ call: CAPPluginCall) {
        call.resolve(["value": true])
    }

    @objc func getPlatform(_ call: CAPPluginCall) {
        call.resolve(["platform": "ios"])
    }

    @objc func testPortReachable(_ call: CAPPluginCall) {
        let port = call.getInt("port") ?? call.getInt("localPort") ?? 0
        guard port > 0 else {
            call.resolve(["reachable": false])
            return
        }
        call.resolve(["reachable": PortForwardManager.shared.isReachable(port: port)])
    }

    @objc func addForwardedPort(_ call: CAPPluginCall) {
        let localPort = call.getInt("localPort") ?? call.getInt("port") ?? 0
        let targetPort = call.getInt("targetPort") ?? call.getInt("port") ?? localPort
        let host = call.getString("host") ?? ""
        guard localPort > 0, targetPort > 0 else {
            call.reject("Invalid port")
            return
        }
        PortForwardManager.shared.register(localPort: localPort, targetPort: targetPort, host: host)
        call.resolve(["ok": true])
        notifyListeners("portForwardResult", data: ["localPort": localPort, "success": true])
    }

    @objc func removeForwardedPort(_ call: CAPPluginCall) {
        let localPort = call.getInt("localPort") ?? call.getInt("port") ?? 0
        guard localPort > 0 else {
            call.reject("Invalid port")
            return
        }
        PortForwardManager.shared.unregister(localPort: localPort)
        call.resolve(["ok": true])
    }

    @objc func stopBackgroundService(_ call: CAPPluginCall) {
        PortForwardManager.shared.stopAll()
        call.resolve(["ok": true])
    }

    @objc func reconnectTunnel(_ call: CAPPluginCall) {
        // iOS MVP binds local TCP ports via Network.framework while the app is foregrounded.
        // There is no long-running background SSH daemon; foreground re-registration is instant.
        call.resolve(["connected": true])
    }

    @objc func openInBrowser(_ call: CAPPluginCall) {
        let urlString = call.getString("url") ?? buildURL(call)
        guard let url = URL(string: urlString) else {
            call.reject("Invalid URL")
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.open(url)
            call.resolve(["ok": true])
        }
    }

    @objc func openInSandbox(_ call: CAPPluginCall) {
        let urlString = call.getString("url") ?? buildURL(call)
        guard let url = URL(string: urlString) else {
            call.reject("Invalid URL")
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let vc = SandboxBrowserViewController(url: url)
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            self.bridge?.viewController?.present(nav, animated: true)
            call.resolve(["ok": true])
        }
    }

    @objc func downloadFile(_ call: CAPPluginCall) {
        let path = call.getString("path") ?? ""
        let serverURL = getServerURL()
        guard !path.isEmpty, let base = URL(string: serverURL) else {
            call.reject("Missing path or server URL")
            return
        }
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? path
        let downloadURL = base.appendingPathComponent("api/file/" + encoded)
        let task = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempURL, _, error in
            if let error = error {
                call.reject(error.localizedDescription)
                return
            }
            guard let tempURL = tempURL else {
                call.reject("Download failed")
                return
            }
            DispatchQueue.main.async {
                let activity = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                self?.bridge?.viewController?.present(activity, animated: true)
                call.resolve(["ok": true])
            }
        }
        task.resume()
    }

    @objc func showServerDialog(_ call: CAPPluginCall) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: "ClawBench 服务端", message: "请输入新的服务端地址", preferredStyle: .alert)
            alert.addTextField { field in
                field.placeholder = "http://服务器IP:20000"
                field.text = self?.getServerURL()
                field.keyboardType = .URL
                field.autocapitalizationType = .none
                field.autocorrectionType = .no
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in call.resolve(["cancelled": true]) })
            alert.addAction(UIAlertAction(title: "保存", style: .default) { _ in
                let value = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                UserDefaults.standard.set(value, forKey: "clawbench.serverUrl")
                call.resolve(["url": value])
            })
            self?.bridge?.viewController?.present(alert, animated: true)
        }
    }

    private func buildURL(_ call: CAPPluginCall) -> String {
        let protocolValue = call.getString("protocol") ?? "http"
        let port = call.getInt("port") ?? call.getInt("localPort") ?? 0
        return PortForwardManager.shared.urlFor(localPort: port, protocolValue: protocolValue)
    }

    private func getServerURL() -> String {
        if let url = UserDefaults.standard.string(forKey: "clawbench.serverUrl"), !url.isEmpty {
            return url
        }
        return ""
    }
}
