import Foundation

enum AgentKind: String, Codable, CaseIterable, Identifiable {
    case claude
    case codex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .claude:
            "Claude Code"
        case .codex:
            "Codex"
        }
    }

    var subtitle: String {
        switch self {
        case .claude:
            "Anthropic-compatible endpoint override"
        case .codex:
            "OpenAI-compatible provider switcher"
        }
    }

    var systemImage: String {
        switch self {
        case .claude:
            "bubble.left.and.bubble.right.fill"
        case .codex:
            "bolt.horizontal.circle.fill"
        }
    }
}

enum CodexAuthMode: String, Codable, CaseIterable, Identifiable {
    case bearer
    case apiKey
    case xApiKey
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bearer:
            "Authorization: Bearer"
        case .apiKey:
            "api-key"
        case .xApiKey:
            "x-api-key"
        case .custom:
            "Custom header"
        }
    }
}

struct ProviderPreset: Identifiable, Codable, Equatable {
    var id: UUID
    var agentKind: AgentKind
    var name: String
    var baseURL: String
    var apiKey: String
    var model: String
    var codexWireAPI: String
    var codexAuthMode: CodexAuthMode
    var codexCustomHeaderName: String
    var codexQueryParameters: String
    var codexExtraHeaders: String
    var claudeTimeoutMilliseconds: Int
    var claudeCACertificatePath: String
    var claudeExtraEnv: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        agentKind: AgentKind,
        name: String,
        baseURL: String,
        apiKey: String = "",
        model: String,
        codexWireAPI: String = "responses",
        codexAuthMode: CodexAuthMode = .bearer,
        codexCustomHeaderName: String = "",
        codexQueryParameters: String = "",
        codexExtraHeaders: String = "",
        claudeTimeoutMilliseconds: Int = 120_000,
        claudeCACertificatePath: String = "",
        claudeExtraEnv: String = "",
        notes: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.agentKind = agentKind
        self.name = name
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.model = model
        self.codexWireAPI = codexWireAPI
        self.codexAuthMode = codexAuthMode
        self.codexCustomHeaderName = codexCustomHeaderName
        self.codexQueryParameters = codexQueryParameters
        self.codexExtraHeaders = codexExtraHeaders
        self.claudeTimeoutMilliseconds = claudeTimeoutMilliseconds
        self.claudeCACertificatePath = claudeCACertificatePath
        self.claudeExtraEnv = claudeExtraEnv
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func starter(for agent: AgentKind) -> ProviderPreset {
        switch agent {
        case .claude:
            ProviderPreset(
                agentKind: .claude,
                name: "Claude Compatible",
                baseURL: "https://your-claude-proxy.example.com/v1",
                model: "claude-sonnet-4-20250514",
                notes: "Apply 后会写入 Xcode 的 ClaudeAgentConfig/settings.json。"
            )
        case .codex:
            ProviderPreset(
                agentKind: .codex,
                name: "Codex Compatible",
                baseURL: "https://your-openai-compatible.example.com/v1",
                model: "gpt-5.2-codex",
                codexWireAPI: "responses",
                notes: "Apply 后会写入 Xcode 的 CodingAssistant/codex/config.toml。"
            )
        }
    }

    func duplicated() -> ProviderPreset {
        var copy = self
        copy.id = UUID()
        copy.name = "\(name) Copy"
        copy.createdAt = .now
        copy.updatedAt = .now
        return copy
    }
}

struct PersistedState: Codable {
    var presets: [ProviderPreset]
}

struct StatusBanner: Equatable {
    enum Kind: Equatable {
        case success
        case error
        case info
    }

    var kind: Kind
    var message: String
}

struct ApplyResult: Equatable {
    var summary: String
    var writtenPaths: [URL]
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isBlank: Bool {
        trimmed.isEmpty
    }
}
