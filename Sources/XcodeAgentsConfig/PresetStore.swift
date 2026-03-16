import Foundation
import SwiftUI

@MainActor
final class PresetStore: ObservableObject {
    @Published var presets: [ProviderPreset]
    @Published var selectedClaudePresetID: UUID?
    @Published var selectedCodexPresetID: UUID?
    @Published var selectedAgent: AgentKind = .claude
    @Published var statusBanner: StatusBanner?

    private let stateURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        stateURL = AppPaths.stateURL()

        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601

        presets = Self.loadPresets(from: stateURL, decoder: decoder)
        if presets.isEmpty {
            presets = [
                .starter(for: .claude),
                .starter(for: .codex)
            ]
            persist()
        }

        reconcileSelection()
    }

    func presets(for agent: AgentKind) -> [ProviderPreset] {
        presets
            .filter { $0.agentKind == agent }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    func selectedPresetID(for agent: AgentKind) -> UUID? {
        switch agent {
        case .claude:
            selectedClaudePresetID
        case .codex:
            selectedCodexPresetID
        }
    }

    func selectionBinding(for agent: AgentKind) -> Binding<UUID?> {
        Binding(
            get: { self.selectedPresetID(for: agent) },
            set: { newValue in
                switch agent {
                case .claude:
                    self.selectedClaudePresetID = newValue
                case .codex:
                    self.selectedCodexPresetID = newValue
                }
            }
        )
    }

    func binding(for presetID: UUID) -> Binding<ProviderPreset>? {
        guard presets.contains(where: { $0.id == presetID }) else {
            return nil
        }

        return Binding(
            get: {
                self.presets.first(where: { $0.id == presetID }) ?? .starter(for: .claude)
            },
            set: { newValue in
                guard let index = self.presets.firstIndex(where: { $0.id == presetID }) else {
                    return
                }

                var updated = newValue
                updated.updatedAt = .now
                self.presets[index] = updated
                self.persist()
            }
        )
    }

    func addPreset(for agent: AgentKind) {
        let preset = ProviderPreset.starter(for: agent)
        presets.append(preset)
        setSelection(preset.id, for: agent)
        persist()
    }

    func duplicateSelection(for agent: AgentKind) {
        guard
            let presetID = selectedPresetID(for: agent),
            let preset = presets.first(where: { $0.id == presetID })
        else {
            return
        }

        let copy = preset.duplicated()
        presets.append(copy)
        setSelection(copy.id, for: agent)
        persist()
    }

    func deleteSelection(for agent: AgentKind) {
        guard let presetID = selectedPresetID(for: agent) else {
            return
        }

        presets.removeAll { $0.id == presetID }
        if presets(for: agent).isEmpty {
            let replacement = ProviderPreset.starter(for: agent)
            presets.append(replacement)
            setSelection(replacement.id, for: agent)
        } else {
            setSelection(presets(for: agent).first?.id, for: agent)
        }
        persist()
    }

    func updateStatus(_ banner: StatusBanner) {
        statusBanner = banner
    }

    func clearStatus() {
        statusBanner = nil
    }

    private func setSelection(_ value: UUID?, for agent: AgentKind) {
        switch agent {
        case .claude:
            selectedClaudePresetID = value
        case .codex:
            selectedCodexPresetID = value
        }
    }

    private func reconcileSelection() {
        if selectedClaudePresetID == nil || presets.first(where: { $0.id == selectedClaudePresetID })?.agentKind != .claude {
            selectedClaudePresetID = presets(for: .claude).first?.id
        }

        if selectedCodexPresetID == nil || presets.first(where: { $0.id == selectedCodexPresetID })?.agentKind != .codex {
            selectedCodexPresetID = presets(for: .codex).first?.id
        }
    }

    private func persist() {
        do {
            let directory = stateURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(PersistedState(presets: presets))
            try data.write(to: stateURL, options: .atomic)
        } catch {
            statusBanner = StatusBanner(kind: .error, message: "保存本地 presets 失败：\(error.localizedDescription)")
        }
    }

    private static func loadPresets(from url: URL, decoder: JSONDecoder) -> [ProviderPreset] {
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(PersistedState.self, from: data).presets
        } catch {
            return []
        }
    }
}
