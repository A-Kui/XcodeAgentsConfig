import AppKit
import Foundation

enum XcodeAgentConfiguratorError: LocalizedError {
    case missingValue(String)
    case xcodeNotFound
    case failedToCloseXcode
    case failedToLaunchXcode(String)

    var errorDescription: String? {
        switch self {
        case .missingValue(let field):
            "请先填写 \(field)"
        case .xcodeNotFound:
            "没有找到可启动的 Xcode.app"
        case .failedToCloseXcode:
            "未能在预期时间内关闭 Xcode，请手动关闭后再试"
        case .failedToLaunchXcode(let details):
            "Xcode 重启失败：\(details)"
        }
    }
}

enum XcodeAgentConfigurator {
    private static let codexManagedProviderKey = "kxcode_agents_config"
    private static let codexMarkers = ManagedBlockMarkers(
        begin: "# BEGIN \(AppMetadata.displayName) managed codex override",
        end: "# END \(AppMetadata.displayName) managed codex override"
    )
    private static let legacyCodexMarkers = ManagedBlockMarkers(
        begin: "# BEGIN \(AppMetadata.legacyDisplayName) managed codex override",
        end: "# END \(AppMetadata.legacyDisplayName) managed codex override"
    )

    static let claudeSettingsURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/settings.json", isDirectory: false)
    static let codexConfigURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Developer/Xcode/CodingAssistant/codex/config.toml", isDirectory: false)

    static func apply(_ preset: ProviderPreset) throws -> ApplyResult {
        switch preset.agentKind {
        case .claude:
            try applyClaude(preset)
        case .codex:
            try applyCodex(preset)
        }
    }

    static func reset(agent: AgentKind) throws -> ApplyResult {
        switch agent {
        case .claude:
            try resetClaude()
        case .codex:
            try resetCodex()
        }
    }

    static func revealConfiguration(for agent: AgentKind) {
        let url: URL = switch agent {
        case .claude:
            claudeSettingsURL
        case .codex:
            codexConfigURL
        }

        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        if !FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
            FileManager.default.createFile(atPath: url.path(percentEncoded: false), contents: nil)
        }

        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @MainActor
    static func restartXcode() async throws {
        let bundleIdentifier = "com.apple.dt.Xcode"
        guard let xcodeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw XcodeAgentConfiguratorError.xcodeNotFound
        }

        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        if !runningApps.isEmpty {
            for app in runningApps {
                _ = app.forceTerminate()
            }

            let deadline = Date().addingTimeInterval(10)
            while Date() < deadline {
                if NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty {
                    break
                }

                try await Task.sleep(for: .milliseconds(200))
            }

            if !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty {
                throw XcodeAgentConfiguratorError.failedToCloseXcode
            }
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: xcodeURL, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: XcodeAgentConfiguratorError.failedToLaunchXcode(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private static func applyClaude(_ preset: ProviderPreset) throws -> ApplyResult {
        try validate(preset)

        let directory = claudeSettingsURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var env: [String: String] = [
            "ANTHROPIC_AUTH_TOKEN": preset.apiKey.trimmed,
            "ANTHROPIC_MODEL": preset.model.trimmed,
            "ANTHROPIC_BASE_URL": normalizedBaseURL(from: preset.baseURL),
            "API_TIMEOUT_MS": String(max(preset.claudeTimeoutMilliseconds, 1)),
            "DISABLE_AUTOUPDATER": "true",
            "DISABLE_BUG_COMMAND": "true"
        ]

        let certificatePath = preset.claudeCACertificatePath.trimmed
        if !certificatePath.isEmpty {
            env["NODE_EXTRA_CA_CERTS"] = certificatePath
            env["SSL_CERT_FILE"] = certificatePath
        }

        for (key, value) in parseKeyValueLines(preset.claudeExtraEnv) {
            env[key] = value
        }

        let payload = [
            "env": env
        ]
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        try data.write(to: claudeSettingsURL, options: .atomic)

        let xcodeDefaults = UserDefaults(suiteName: "com.apple.dt.Xcode")
        xcodeDefaults?.set(preset.apiKey.trimmed, forKey: "IDEChatClaudeAgentAPIKeyOverride")
        xcodeDefaults?.set("custom", forKey: "IDEChatClaudeAgentModelConfigurationAlias")
        xcodeDefaults?.synchronize()

        return ApplyResult(
            summary: "Claude 自定义配置已写入，建议完全退出并重新打开 Xcode。",
            writtenPaths: [claudeSettingsURL]
        )
    }

    private static func applyCodex(_ preset: ProviderPreset) throws -> ApplyResult {
        try validate(preset)

        let directory = codexConfigURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let existingContents = (try? String(contentsOf: codexConfigURL, encoding: .utf8)) ?? ""
        let cleanedContents = removingManagedCodexBlocks(from: existingContents)
        let managedBlock = codexManagedBlock(for: preset)
        let mergedContents = mergeManagedCodexBlock(managedBlock, into: cleanedContents)

        try mergedContents.write(to: codexConfigURL, atomically: true, encoding: .utf8)

        return ApplyResult(
            summary: "Codex provider 已切换到 \(preset.name)，建议完全退出并重新打开 Xcode。",
            writtenPaths: [codexConfigURL]
        )
    }

    private static func resetClaude() throws -> ApplyResult {
        if FileManager.default.fileExists(atPath: claudeSettingsURL.path(percentEncoded: false)) {
            try FileManager.default.removeItem(at: claudeSettingsURL)
        }

        let xcodeDefaults = UserDefaults(suiteName: "com.apple.dt.Xcode")
        xcodeDefaults?.removeObject(forKey: "IDEChatClaudeAgentAPIKeyOverride")
        xcodeDefaults?.set("default", forKey: "IDEChatClaudeAgentModelConfigurationAlias")
        xcodeDefaults?.synchronize()

        return ApplyResult(
            summary: "Claude 自定义覆盖已移除，Xcode 将回到官方登录流。",
            writtenPaths: [claudeSettingsURL]
        )
    }

    private static func resetCodex() throws -> ApplyResult {
        let existingContents = (try? String(contentsOf: codexConfigURL, encoding: .utf8)) ?? ""
        let cleanedContents = removingManagedCodexBlocks(from: existingContents)
        try FileManager.default.createDirectory(at: codexConfigURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try cleanedContents.write(to: codexConfigURL, atomically: true, encoding: .utf8)

        return ApplyResult(
            summary: "Codex 自定义 provider block 已移除。",
            writtenPaths: [codexConfigURL]
        )
    }

    private static func validate(_ preset: ProviderPreset) throws {
        if preset.name.isBlank {
            throw XcodeAgentConfiguratorError.missingValue("名称")
        }
        if preset.baseURL.isBlank {
            throw XcodeAgentConfiguratorError.missingValue("Base URL")
        }
        if preset.apiKey.isBlank {
            throw XcodeAgentConfiguratorError.missingValue("API Key")
        }
        if preset.model.isBlank {
            throw XcodeAgentConfiguratorError.missingValue("Model")
        }
    }

    private static func normalizedBaseURL(from value: String) -> String {
        value.trimmed
    }

    private static func codexManagedBlock(for preset: ProviderPreset) -> String {
        var headers = parseKeyValueLines(preset.codexExtraHeaders)

        switch preset.codexAuthMode {
        case .bearer:
            headers["Authorization"] = "Bearer \(preset.apiKey.trimmed)"
        case .apiKey:
            headers["api-key"] = preset.apiKey.trimmed
        case .xApiKey:
            headers["x-api-key"] = preset.apiKey.trimmed
        case .custom:
            let customHeaderName = preset.codexCustomHeaderName.trimmed.isEmpty ? "Authorization" : preset.codexCustomHeaderName.trimmed
            headers[customHeaderName] = preset.apiKey.trimmed
        }

        let queryParameters = parseKeyValueLines(preset.codexQueryParameters)
        let baseURL = normalizedBaseURL(from: preset.baseURL)
        let model = preset.model.trimmed
        let wireAPI = preset.codexWireAPI.trimmed.isEmpty ? "responses" : preset.codexWireAPI.trimmed

        var lines = [
            codexMarkers.begin,
            "model_provider = \(tomlString(codexManagedProviderKey))",
            "model = \(tomlString(model))",
            "",
            "[model_providers.\(codexManagedProviderKey)]",
            "name = \(tomlString(preset.name.trimmed))",
            "base_url = \(tomlString(baseURL))",
            "wire_api = \(tomlString(wireAPI))",
            "requires_openai_auth = false",
            "supports_websockets = false"
        ]

        if !headers.isEmpty {
            lines.append("http_headers = \(tomlInlineTable(from: headers))")
        }

        if !queryParameters.isEmpty {
            lines.append("query_params = \(tomlInlineTable(from: queryParameters))")
        }

        lines.append(codexMarkers.end)
        return lines.joined(separator: "\n")
    }

    private static func mergeManagedCodexBlock(_ managedBlock: String, into existingContents: String) -> String {
        let trimmedExisting = existingContents.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedExisting.isEmpty {
            return managedBlock + "\n"
        }

        let lines = existingContents.components(separatedBy: .newlines)
        if let firstTableIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("[") }) {
            let beforeTable = lines[..<firstTableIndex].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let tableAndAfter = lines[firstTableIndex...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let prefix = beforeTable.isEmpty ? managedBlock : managedBlock + "\n\n" + beforeTable
            return prefix + "\n\n" + tableAndAfter + "\n"
        }

        return managedBlock + "\n\n" + trimmedExisting + "\n"
    }

    static func removingManagedCodexBlocks(from contents: String) -> String {
        [legacyCodexMarkers, codexMarkers]
            .reduce(contents) { partialResult, markers in
                removingManagedBlock(from: partialResult, beginMarker: markers.begin, endMarker: markers.end)
            }
            .replacingOccurrences(of: "\n\n\n", with: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removingManagedBlock(from contents: String, beginMarker: String, endMarker: String) -> String {
        guard
            let startRange = contents.range(of: beginMarker),
            let endRange = contents.range(of: endMarker, range: startRange.lowerBound..<contents.endIndex)
        else {
            return contents
        }

        var cleaned = contents
        cleaned.removeSubrange(startRange.lowerBound..<endRange.upperBound)
        return cleaned
    }

    private static func parseKeyValueLines(_ source: String) -> [String: String] {
        source
            .components(separatedBy: .newlines)
            .compactMap { line -> (String, String)? in
                let trimmedLine = line.trimmed
                guard !trimmedLine.isEmpty, !trimmedLine.hasPrefix("#") else {
                    return nil
                }

                if let separator = trimmedLine.firstIndex(of: "=") {
                    let key = String(trimmedLine[..<separator]).trimmed
                    let value = String(trimmedLine[trimmedLine.index(after: separator)...]).trimmed
                    guard !key.isEmpty else { return nil }
                    return (key, value)
                }

                if let separator = trimmedLine.firstIndex(of: ":") {
                    let key = String(trimmedLine[..<separator]).trimmed
                    let value = String(trimmedLine[trimmedLine.index(after: separator)...]).trimmed
                    guard !key.isEmpty else { return nil }
                    return (key, value)
                }

                return nil
            }
            .reduce(into: [String: String]()) { partialResult, item in
                partialResult[item.0] = item.1
            }
    }

    private static func tomlInlineTable(from dictionary: [String: String]) -> String {
        let pairs = dictionary
            .sorted { lhs, rhs in lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending }
            .map { key, value in
                "\(tomlString(key)) = \(tomlString(value))"
            }
        return "{ " + pairs.joined(separator: ", ") + " }"
    }

    private static func tomlString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "\"\(escaped)\""
    }
}

private struct ManagedBlockMarkers {
    let begin: String
    let end: String
}
