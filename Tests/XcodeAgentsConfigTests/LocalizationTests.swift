import Foundation
import Testing
@testable import XcodeAgentsConfig

struct LocalizationTests {
    @Test
    func starterPresetsUseRequestedLanguage() {
        let englishClaude = ProviderPreset.starter(for: .claude, language: .english)
        let chineseCodex = ProviderPreset.starter(for: .codex, language: .simplifiedChinese)

        #expect(englishClaude.name == "Claude Compatible")
        #expect(englishClaude.notes == "Applying will write to Xcode's `ClaudeAgentConfig/settings.json`.")
        #expect(chineseCodex.name == "Codex 兼容线路")
        #expect(chineseCodex.notes == "Apply 后会写入 Xcode 的 CodingAssistant/codex/config.toml。")
    }

    @Test
    func duplicatedPresetUsesSelectedLanguageSuffix() {
        let preset = ProviderPreset(
            agentKind: .codex,
            name: "Demo",
            baseURL: "https://example.com/v1",
            model: "gpt-5-codex"
        )

        #expect(preset.duplicated(language: .english).name == "Demo Copy")
        #expect(preset.duplicated(language: .simplifiedChinese).name == "Demo 副本")
    }

    @Test
    func persistedStateDecodesLegacyPayloadWithoutLanguage() throws {
        let decoder = JSONDecoder()
        let state = try decoder.decode(PersistedState.self, from: Data(#"{"presets":[]}"#.utf8))

        #expect(state.presets.isEmpty)
        #expect(state.language == nil)
    }

    @Test
    func configuratorErrorsFollowSelectedLanguage() {
        let error = XcodeAgentConfiguratorError.missingValue("Base URL")

        #expect(error.message(in: .english) == "Please fill in Base URL")
        #expect(error.message(in: .simplifiedChinese) == "请先填写 Base URL")
    }
}
