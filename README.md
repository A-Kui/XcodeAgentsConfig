# kXcodeAgentsConfig

一个 SwiftUI macOS 原型，用来管理 Xcode 26.3 (17C529) 的第三方 `Claude Code` / `Codex` Agent 配置，并一键应用到 Xcode 当前会读取的本地文件。

## 当前能力

- 为 `Claude Code` 维护多组 `Base URL + API Key + Model` presets。
- 为 `Codex` 维护多组 OpenAI-compatible presets，并支持：
  - `Authorization: Bearer`
  - `api-key`
  - `x-api-key`
  - 自定义 header 名称
- 支持为 `Codex` 增加额外 headers 和 query parameters。
- 点击 `Apply to Xcode` 后，直接写入 Xcode 当前使用的配置位置。

## App 自身配置

- App 维护的 preset 文件：
  - `~/Library/Application Support/kXcodeAgentsConfig/presets.json`
  - 如果检测到旧版 `~/Library/Application Support/XcodeAgentsConfig/presets.json`，首次启动会自动迁移
- SwiftPM 可执行入口：
  - `Sources/XcodeAgentsConfig/XcodeAgentsConfigApp.swift`
- 为了让 SwiftPM 直接启动时成为正常前台 macOS 窗口应用，启动阶段会调用：
  - `NSApp.setActivationPolicy(.regular)`
  - `NSApp.activate(ignoringOtherApps: true)`

## 写入位置

### Claude

- `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/settings.json`
- `com.apple.dt.Xcode` defaults:
  - `IDEChatClaudeAgentAPIKeyOverride`
  - `IDEChatClaudeAgentModelConfigurationAlias`

### Codex

- `~/Library/Developer/Xcode/CodingAssistant/codex/config.toml`
- App 会在文件顶部插入一个带 marker 的 managed block，尽量保留你原有的其他配置。

## 实际验证过的关键结论

### 启动层面

- `swift build` 可以正常通过。
- `swift run` / 直接运行 `.build/debug/kXcodeAgentsConfig` 可以启动 GUI。
- 如果不显式设置激活策略，系统会把它识别成 `BackgroundOnly`，进程存在但不是正常前台窗口应用。
- 修正后，系统会把它识别成 `Foreground`。

### Claude

- `Claude` 这条链路是通过本地覆盖配置工作的，不是 Apple 官方公开配置入口。
- 目前使用的关键方式是：
  - 写 `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/settings.json`
  - 设置 `com.apple.dt.Xcode` 的 `IDEChatClaudeAgentAPIKeyOverride`
  - 设置 `com.apple.dt.Xcode` 的 `IDEChatClaudeAgentModelConfigurationAlias`
- App 写入的主要环境变量包括：
  - `ANTHROPIC_AUTH_TOKEN`
  - `ANTHROPIC_MODEL`
  - `ANTHROPIC_BASE_URL`
  - 可选 `NODE_EXTRA_CA_CERTS`
  - 可选 `SSL_CERT_FILE`

### Codex

- `Codex` 当前走的是官方 `config.toml` custom provider 思路。
- App 会在 `config.toml` 顶部写入一个带 marker 的 block，核心字段包括：
  - `model_provider`
  - `model`
  - `[model_providers.<name>]`
  - `base_url`
  - `wire_api`
  - `http_headers`
  - `query_params`
- 应用配置后，建议完全退出并重新打开 Xcode，而不是只关闭窗口。

## 第三方 Codex API 实测记录

下面这些结论是针对：

- 某个第三方 Codex 兼容接口
- 接口：`POST /responses`

### 鉴权

- `api-key: <KEY>` 会返回：
  - `401 {"error":"缺少 API Key"}`
- `x-api-key: <KEY>` 会返回：
  - `401 {"error":"Unauthorized"}`
- `Authorization: Bearer <KEY>` 可以通过鉴权。

结论：

- 某些第三方 Codex 线路应优先使用 `Authorization: Bearer`，不要默认使用 `api-key`。

### 模型

- `gpt-5.4` 虽然会出现在 `/models` 列表里，但对 Codex `/responses` 实际调用会返回：
  - `400`
  - `The 'gpt-5.4' model is not supported when using Codex with a ChatGPT account.`
- `gpt-5-codex` 已实测可返回 `200`。

结论：

- 对某些第三方 Codex 预设，当前优先使用：
  - `model = "gpt-5-codex"`

### 请求体

- 对某些第三方 Codex `/responses` 接口，把 `input` 直接写成字符串会报错：
  - `Input must be a list`
- 实测可用的最小结构类似：

```json
{
  "model": "gpt-5-codex",
  "input": [
    {
      "role": "user",
      "content": [
        {
          "type": "input_text",
          "text": "ping"
        }
      ]
    }
  ]
}
```

## 当前推荐的第三方 Codex 预设

- `Base URL`
  - `https://your-codex-provider.example.com/v1`
- `Auth header`
  - `Authorization: Bearer`
- `Model`
  - `gpt-5-codex`
- `Wire API`
  - `responses`

## 本地验证依据

- 你给的 gist 说明了 Claude 这边可以通过 `settings.json` + `defaults` 覆盖官方登录流：
  - <https://gist.github.com/zoltan-magyar/be846eb36cf5ee33c882ef5f932b754b>
- 本机 Xcode 26.3 (17C529) 实际存在以下目录：
  - `~/Library/Developer/Xcode/CodingAssistant/Agents/Versions/17C529/claude`
  - `~/Library/Developer/Xcode/CodingAssistant/Agents/Versions/17C529/codex`
  - `~/Library/Developer/Xcode/CodingAssistant/codex/config.toml`
- Codex provider 字段参考官方 OpenAI 文档：
  - <https://developers.openai.com/codex/config>

## 运行

在仓库根目录执行：

```bash
swift run
```

或者直接用 Xcode 打开 `Package.swift`。

## 打包

在仓库根目录执行：

```bash
./scripts/package_app.sh 1.0
```

脚本会使用仓库根目录的 `icon.png` 生成应用图标。

生成产物：

- `dist/kXcodeAgentsConfig.app`
- `dist/kXcodeAgentsConfig-1.0-macOS.zip`

如果需要生成可分发的拖拽安装镜像：

```bash
./scripts/package_dmg.sh 1.0
```

生成产物：

- `dist/kXcodeAgentsConfig-1.0.dmg`

## 目前的边界

- `Claude` 的第三方接入是基于 gist 和本机行为做的“可用型覆盖”，不是 Apple 官方公开 API。
- `Codex` 目前走的是官方 `config.toml` 的 custom model provider 方案。
- 某些第三方代理即使在 `/models` 返回了某个模型，也不代表它在 `Codex /responses` 场景下真实可用，仍然需要实测。
- README 中关于第三方 Codex API 的结论是基于本机当次验证结果，后续可能随服务端策略变化。
