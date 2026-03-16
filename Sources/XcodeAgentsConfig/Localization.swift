import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    static var defaultValue: AppLanguage {
        let preferredIdentifier = Locale.preferredLanguages.first ?? Locale.current.identifier
        return preferredIdentifier.hasPrefix("zh") ? .simplifiedChinese : .english
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .simplifiedChinese:
            "中文"
        }
    }

    func localized(english: String, chinese: String) -> String {
        switch self {
        case .english:
            english
        case .simplifiedChinese:
            chinese
        }
    }

    func message(for error: Error) -> String {
        if let configuratorError = error as? XcodeAgentConfiguratorError {
            return configuratorError.message(in: self)
        }

        return error.localizedDescription
    }
}

struct AppStrings {
    let language: AppLanguage

    var appSubtitle: String {
        language.localized(
            english: "Manage third-party Base URL / API Key presets for Claude Code and Codex in Xcode 26.3 (17C529), then apply them with one click.",
            chinese: "为 Xcode 26.3 (17C529) 的 Claude Code 和 Codex 维护第三方 Base URL / API Key 列表，并一键应用。"
        )
    }

    var languageLabel: String {
        language.localized(english: "Language", chinese: "语言")
    }

    func headerLinkTitle(for agent: AgentKind) -> String {
        switch agent {
        case .claude:
            language.localized(
                english: "Claude writes `ClaudeAgentConfig/settings.json`",
                chinese: "Claude 写入 `ClaudeAgentConfig/settings.json`"
            )
        case .codex:
            language.localized(
                english: "Codex writes `CodingAssistant/codex/config.toml`",
                chinese: "Codex 写入 `CodingAssistant/codex/config.toml`"
            )
        }
    }

    var restartRecommendationTitle: String {
        language.localized(
            english: "Fully restart Xcode after applying",
            chinese: "应用后建议完全重启 Xcode"
        )
    }

    var restartRecommendationHelp: String {
        language.localized(
            english: "Force-quit and relaunch Xcode after confirmation",
            chinese: "点击确认后强制关闭并重新打开 Xcode"
        )
    }

    func revealConfigurationStatus(for agent: AgentKind) -> String {
        language.localized(
            english: "Revealed the \(agent.title(in: language)) config file in Finder.",
            chinese: "已在访达中定位 \(agent.title(in: language)) 配置文件。"
        )
    }

    func revealConfigurationHelp(for agent: AgentKind) -> String {
        language.localized(
            english: "Open the \(agent.title(in: language)) config file in Finder",
            chinese: "点击在访达中打开 \(agent.title(in: language)) 配置文件"
        )
    }

    var restartAlertTitle: String {
        language.localized(english: "Restart Xcode?", chinese: "重启 Xcode？")
    }

    var cancel: String {
        language.localized(english: "Cancel", chinese: "取消")
    }

    var restartNow: String {
        language.localized(english: "I've saved everything, restart now", chinese: "我已保存，立即重启")
    }

    var restartAlertMessage: String {
        language.localized(
            english: "Before continuing, make sure you've handled any unsaved code, breakpoint changes, and other edits in Xcode. Continuing will force-quit the current Xcode instance and reopen it immediately.",
            chinese: "继续前，请先确认 Xcode 里的代码、断点调整和未保存编辑都已经处理完成。继续后会强制退出当前 Xcode，并立即重新打开。"
        )
    }

    var restartInProgress: String {
        language.localized(english: "Restarting Xcode...", chinese: "正在重启 Xcode...")
    }

    var restartSucceeded: String {
        language.localized(
            english: "Force-quit and reopened Xcode.",
            chinese: "已强制关闭并重新打开 Xcode。"
        )
    }

    var noPresetSelected: String {
        language.localized(english: "No Preset Selected", chinese: "未选择预设")
    }

    var add: String {
        language.localized(english: "Add", chinese: "新增")
    }

    var duplicate: String {
        language.localized(english: "Duplicate", chinese: "复制")
    }

    var delete: String {
        language.localized(english: "Delete", chinese: "删除")
    }

    var presetNamePlaceholder: String {
        language.localized(english: "Preset name", chinese: "预设名称")
    }

    var baseURL: String { "Base URL" }

    var model: String { "Model" }

    var auth: String {
        language.localized(english: "Auth", chinese: "鉴权")
    }

    var notSet: String {
        language.localized(english: "Not set", chinese: "未设置")
    }

    var anthropicEnv: String {
        language.localized(english: "Anthropic env", chinese: "Anthropic 环境变量")
    }

    var currentPreset: String {
        language.localized(english: "Current Preset", chinese: "当前预设")
    }

    var configuration: String {
        language.localized(english: "Configuration", chinese: "配置")
    }

    var apiKey: String { "API Key" }

    var authHeader: String {
        language.localized(english: "Auth header", chinese: "鉴权 Header")
    }

    var customHeaderName: String {
        language.localized(english: "Custom header name", chinese: "自定义 Header 名称")
    }

    var wireAPI: String { "Wire API" }

    var queryParameters: String {
        language.localized(english: "Query parameters", chinese: "Query 参数")
    }

    var queryParametersHint: String {
        language.localized(
            english: "One `key=value` pair per line, for example `api-version=2025-04-01-preview`.",
            chinese: "每行一个 `key=value`，例如 `api-version=2025-04-01-preview`。"
        )
    }

    var extraHeaders: String {
        language.localized(english: "Extra headers", chinese: "额外 Headers")
    }

    var extraHeadersHint: String {
        language.localized(
            english: "One `Header=Value` pair per line. The API key header is added automatically when applying.",
            chinese: "每行一个 `Header=Value`。API key header 会在应用时自动补进去。"
        )
    }

    func timeout(_ milliseconds: Int) -> String {
        language.localized(
            english: "Timeout: \(milliseconds) ms",
            chinese: "超时：\(milliseconds) 毫秒"
        )
    }

    var caCertificatePathOptional: String {
        language.localized(
            english: "CA certificate path (optional)",
            chinese: "CA 证书路径（可选）"
        )
    }

    var extraEnv: String {
        language.localized(english: "Extra env", chinese: "额外环境变量")
    }

    var extraEnvHint: String {
        language.localized(
            english: "One `KEY=VALUE` pair per line. These are written alongside `ANTHROPIC_BASE_URL` and `ANTHROPIC_MODEL`.",
            chinese: "每行一个 `KEY=VALUE`。会和 `ANTHROPIC_BASE_URL` / `ANTHROPIC_MODEL` 一起写入。"
        )
    }

    var notes: String {
        language.localized(english: "Notes", chinese: "备注")
    }

    var applyToXcode: String {
        language.localized(english: "Apply to Xcode", chinese: "应用到 Xcode")
    }

    var revealConfigFile: String {
        language.localized(english: "Reveal Config File", chinese: "定位配置文件")
    }

    var revealConfigFileStatus: String {
        language.localized(
            english: "Revealed the config file in Finder.",
            chinese: "已在访达中定位配置文件。"
        )
    }

    var resetToOfficial: String {
        language.localized(english: "Reset to Official", chinese: "恢复官方配置")
    }

    var actions: String {
        language.localized(english: "Actions", chinese: "操作")
    }

    func helpText(for agent: AgentKind) -> String {
        switch agent {
        case .claude:
            language.localized(
                english: "Claude writes to `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/settings.json` and sets `com.apple.dt.Xcode` defaults for `IDEChatClaudeAgentAPIKeyOverride` and `IDEChatClaudeAgentModelConfigurationAlias`.",
                chinese: "Claude 会写入 `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/settings.json`，并设置 `com.apple.dt.Xcode` 的 `IDEChatClaudeAgentAPIKeyOverride` / `IDEChatClaudeAgentModelConfigurationAlias`。"
            )
        case .codex:
            language.localized(
                english: "Codex inserts a managed block at the top of `~/Library/Developer/Xcode/CodingAssistant/codex/config.toml` while preserving any other existing configuration.",
                chinese: "Codex 会在 `~/Library/Developer/Xcode/CodingAssistant/codex/config.toml` 顶部插入一个受管 block，保留其他已有配置。"
            )
        }
    }

    var claudeStarterName: String {
        language.localized(english: "Claude Compatible", chinese: "Claude 兼容线路")
    }

    var claudeStarterNotes: String {
        language.localized(
            english: "Applying will write to Xcode's `ClaudeAgentConfig/settings.json`.",
            chinese: "Apply 后会写入 Xcode 的 ClaudeAgentConfig/settings.json。"
        )
    }

    var codexStarterName: String {
        language.localized(english: "Codex Compatible", chinese: "Codex 兼容线路")
    }

    var codexStarterNotes: String {
        language.localized(
            english: "Applying will write to Xcode's `CodingAssistant/codex/config.toml`.",
            chinese: "Apply 后会写入 Xcode 的 CodingAssistant/codex/config.toml。"
        )
    }

    func duplicatedName(from name: String) -> String {
        language.localized(english: "\(name) Copy", chinese: "\(name) 副本")
    }

    func missingValue(_ field: String) -> String {
        language.localized(english: "Please fill in \(field)", chinese: "请先填写 \(field)")
    }

    var xcodeNotFound: String {
        language.localized(
            english: "Unable to find a launchable Xcode.app",
            chinese: "没有找到可启动的 Xcode.app"
        )
    }

    var failedToCloseXcode: String {
        language.localized(
            english: "Xcode did not close within the expected time. Please close it manually and try again.",
            chinese: "未能在预期时间内关闭 Xcode，请手动关闭后再试"
        )
    }

    func failedToLaunchXcode(details: String) -> String {
        language.localized(
            english: "Failed to relaunch Xcode: \(details)",
            chinese: "Xcode 重启失败：\(details)"
        )
    }

    var fieldNameName: String {
        language.localized(english: "Name", chinese: "名称")
    }

    var fieldNameBaseURL: String { "Base URL" }

    var fieldNameAPIKey: String { "API Key" }

    var fieldNameModel: String { "Model" }

    var claudeApplySummary: String {
        language.localized(
            english: "Claude custom settings were written. Fully quit and reopen Xcode to apply them.",
            chinese: "Claude 自定义配置已写入，建议完全退出并重新打开 Xcode。"
        )
    }

    func codexApplySummary(presetName: String) -> String {
        language.localized(
            english: "Codex provider switched to \(presetName). Fully quit and reopen Xcode to apply it.",
            chinese: "Codex provider 已切换到 \(presetName)，建议完全退出并重新打开 Xcode。"
        )
    }

    var claudeResetSummary: String {
        language.localized(
            english: "Claude custom overrides were removed. Xcode will return to the official sign-in flow.",
            chinese: "Claude 自定义覆盖已移除，Xcode 将回到官方登录流。"
        )
    }

    var codexResetSummary: String {
        language.localized(
            english: "The custom Codex provider block was removed.",
            chinese: "Codex 自定义 provider block 已移除。"
        )
    }

    func saveLocalPresetsFailed(details: String) -> String {
        language.localized(
            english: "Failed to save local presets: \(details)",
            chinese: "保存本地 presets 失败：\(details)"
        )
    }
}

extension AgentKind {
    func title(in language: AppLanguage) -> String {
        switch self {
        case .claude:
            "Claude Code"
        case .codex:
            "Codex"
        }
    }

    func subtitle(in language: AppLanguage) -> String {
        switch self {
        case .claude:
            language.localized(
                english: "Anthropic-compatible endpoint override",
                chinese: "Anthropic 兼容接口覆写"
            )
        case .codex:
            language.localized(
                english: "OpenAI-compatible provider switcher",
                chinese: "OpenAI 兼容 Provider 切换"
            )
        }
    }
}

extension CodexAuthMode {
    func title(in language: AppLanguage) -> String {
        switch self {
        case .bearer:
            "Authorization: Bearer"
        case .apiKey:
            "api-key"
        case .xApiKey:
            "x-api-key"
        case .custom:
            language.localized(english: "Custom header", chinese: "自定义 Header")
        }
    }
}
