# ClawBench iOS Capacitor Client

这是 ClawBench 的 iOS Capacitor 客户端壳，连接远程 ClawBench 服务端使用。

## 当前功能

- Capacitor iOS App
- 首次输入 ClawBench 服务端地址
- 使用 Capacitor Preferences 保存地址
- 自动跳转到服务端 Web UI
- 支持 HTTP 内网服务端地址，CI 自动 patch ATS
- 在 App 内加载 ClawBench Web UI，因此服务端已有的文件、聊天、Git 页面可直接使用
- 注入 `window.AndroidNative` 兼容桥，让现有 ClawBench 前端可在 iOS App 模式下工作
- iOS 原生能力：
  - `openInBrowser`：外部 Safari 打开
  - `openInSandbox`：non-persistent WKWebView 沙盒浏览
  - `downloadFile`：下载后调用 iOS 分享面板
  - `showServerDialog`：原生服务端地址输入框
- iOS 端口转发 MVP：使用 Network.framework 在前台绑定 `127.0.0.1:<localPort>`，转发到服务端同主机的目标端口
- GitHub Actions 构建 unsigned IPA

## 重要说明：iOS SSH/端口转发限制

当前实现的是 **前台本地 TCP 端口转发 MVP**，不是 Android 那种后台常驻 SSH 服务：

- App 在前台时可绑定本地端口并转发 TCP 流量
- 目标主机默认取 ClawBench 服务端地址的 host；如果 ClawBench 前端传入 host，则使用传入 host
- iOS 切后台后网络转发可能被系统挂起，这是系统限制
- 后续如需真正 SSH direct-tcpip 隧道，可在 `ios-native/PortForwardManager.swift` 内替换为 NMSSH / libssh2 实现

## 服务端要求

需要先部署 ClawBench 服务端，例如：

```bash
wget https://github.com/xulongzhe/clawbench/releases/latest/download/clawbench-linux-amd64.zip
unzip clawbench-linux-amd64.zip
cd clawbench
./server.sh
```

然后在 iOS App 输入：

```text
http://服务器IP:20000
```

公网建议使用 HTTPS 域名。

## 构建 IPA

GitHub Actions:

1. 打开仓库 Actions
2. 运行 `Build iOS Capacitor unsigned IPA`
3. 下载 Artifact：`ClawBench-iOS-unsigned`

注意：当前产物是 unsigned IPA，普通 iPhone 安装需要 Apple Developer 证书和 provisioning profile 重签名。
