import Foundation

enum AgentKind: String, Codable, CaseIterable, Identifiable {
    case claude
    case codex

    var id: String { rawValue }

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

    static func starter(for agent: AgentKind, language: AppLanguage = .defaultValue) -> ProviderPreset {
        let strings = AppStrings(language: language)

        return switch agent {
        case .claude:
            ProviderPreset(
                agentKind: .claude,
                name: strings.claudeStarterName,
                baseURL: "https://your-claude-proxy.example.com/v1",
                model: "claude-sonnet-4-20250514",
                notes: strings.claudeStarterNotes
            )
        case .codex:
            ProviderPreset(
                agentKind: .codex,
                name: strings.codexStarterName,
                baseURL: "https://your-openai-compatible.example.com/v1",
                model: "gpt-5.2-codex",
                codexWireAPI: "responses",
                notes: strings.codexStarterNotes
            )
        }
    }

    func duplicated(language: AppLanguage) -> ProviderPreset {
        var copy = self
        copy.id = UUID()
        copy.name = AppStrings(language: language).duplicatedName(from: name)
        copy.createdAt = .now
        copy.updatedAt = .now
        return copy
    }
}

struct PersistedState: Codable {
    var presets: [ProviderPreset]
    var language: AppLanguage?
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
