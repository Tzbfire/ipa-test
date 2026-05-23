# BasicIPA

一个最基础的原生 iOS Swift 示例项目，用 GitHub Actions 在 macOS runner 上编译并打包 unsigned IPA。

## 功能

打开后显示：

- `Hello IPA`
- `Built by GitHub Actions`

## 项目结构

```text
.
├── project.yml                         # XcodeGen 项目配置
├── BasicIPA/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── ViewController.swift
│   ├── LaunchScreen.storyboard
│   └── Assets.xcassets/
└── .github/workflows/build-ipa.yml      # GitHub Actions 编译 IPA
```

## 如何使用 GitHub Actions 编译

1. 新建一个 GitHub 仓库。
2. 把本目录所有文件上传到仓库根目录。
3. 进入 GitHub 仓库页面：`Actions` → `Build unsigned IPA` → `Run workflow`。
4. 编译完成后，在 workflow run 的 `Artifacts` 下载 `BasicIPA-unsigned.ipa`。

## 注意

这个工作流生成的是 **unsigned IPA**，通常可用于后续重签名、越狱环境测试、或作为 CI 构建产物。  
如果要安装到普通 iPhone，需要使用你的 Apple Developer 证书和 provisioning profile 进行签名。
