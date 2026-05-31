# ClawBench iOS Capacitor Client

这是 ClawBench 的 iOS Capacitor 客户端壳，连接远程 ClawBench 服务端使用。

## 当前功能

- Capacitor iOS App
- 首次输入 ClawBench 服务端地址
- 使用 Capacitor Preferences 保存地址
- 自动跳转到服务端 Web UI
- 支持 HTTP 内网服务端地址，已在 CI 中 patch ATS
- GitHub Actions 构建 unsigned IPA

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

## 后续增强方向

- `useNativeBridge` 抽象层接入 ClawBench 前端
- iOS 文件下载：Filesystem + Share
- iOS 外部 Safari 打开
- iOS 沙盒 WKWebView
- iOS SSH 隧道插件
- APNs / 本地通知

注意：当前产物是 unsigned IPA，普通 iPhone 安装需要 Apple Developer 证书和 provisioning profile 重签名。
