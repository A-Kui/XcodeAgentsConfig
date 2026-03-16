import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: PresetStore
    @State private var showRestartXcodeConfirmation = false
    @State private var isRestartingXcode = false

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $store.selectedAgent) {
                AgentWorkspaceView(store: store, agent: .claude)
                    .tabItem {
                        Label(AgentKind.claude.title, systemImage: AgentKind.claude.systemImage)
                    }
                    .tag(AgentKind.claude)

                AgentWorkspaceView(store: store, agent: .codex)
                    .tabItem {
                        Label(AgentKind.codex.title, systemImage: AgentKind.codex.systemImage)
                    }
                    .tag(AgentKind.codex)
            }
            .frame(minWidth: 1000, minHeight: 700)

            if let banner = store.statusBanner {
                StatusBannerView(banner: banner)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("重启 Xcode？", isPresented: $showRestartXcodeConfirmation) {
            Button("取消", role: .cancel) {}
            Button("我已保存，立即重启", role: .destructive) {
                restartXcode()
            }
            .disabled(isRestartingXcode)
        } message: {
            Text("继续前，请先确认 Xcode 里的代码、断点调整和未保存编辑都已经处理完成。继续后会强制退出当前 Xcode，并立即重新打开。")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppMetadata.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("为 Xcode 26.3 (17C529) 的 Claude Code 和 Codex 维护第三方 Base URL / API Key 列表，并一键应用。")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                headerLink(
                    title: "Claude 写入 `ClaudeAgentConfig/settings.json`",
                    agent: .claude
                )

                headerLink(
                    title: "Codex 写入 `CodingAssistant/codex/config.toml`",
                    agent: .codex
                )

                headerActionLink(
                    title: "应用后建议完全重启 Xcode",
                    systemImage: "arrow.clockwise.circle.fill",
                    help: "点击确认后强制关闭并重新打开 Xcode"
                ) {
                    showRestartXcodeConfirmation = true
                }
            }
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.69, blue: 0.42),
                    Color(red: 0.82, green: 0.90, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.28)
        )
    }

    private func revealConfiguration(for agent: AgentKind) {
        XcodeAgentConfigurator.revealConfiguration(for: agent)
        store.updateStatus(.init(kind: .info, message: "已在访达中定位 \(agent.title) 配置文件。"))
    }

    @ViewBuilder
    private func headerLink(title: String, agent: AgentKind) -> some View {
        headerActionLink(
            title: title,
            systemImage: "link.circle.fill",
            help: "点击在访达中打开 \(agent.title) 配置文件"
        ) {
            revealConfiguration(for: agent)
        }
    }

    @ViewBuilder
    private func headerActionLink(
        title: String,
        systemImage: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(linkColor)

                Text(.init(title))
                    .underline()
                    .foregroundStyle(linkColor)

                Image(systemName: "arrow.up.forward.square")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(linkColor.opacity(0.9))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private func restartXcode() {
        guard !isRestartingXcode else {
            return
        }

        isRestartingXcode = true
        store.updateStatus(.init(kind: .info, message: "正在重启 Xcode..."))

        Task {
            do {
                try await XcodeAgentConfigurator.restartXcode()
                await MainActor.run {
                    isRestartingXcode = false
                    store.updateStatus(.init(kind: .success, message: "已强制关闭并重新打开 Xcode。"))
                }
            } catch {
                await MainActor.run {
                    isRestartingXcode = false
                    store.updateStatus(.init(kind: .error, message: error.localizedDescription))
                }
            }
        }
    }

    private var linkColor: Color {
        Color(red: 0.10, green: 0.38, blue: 0.82)
    }
}

private struct AgentWorkspaceView: View {
    @ObservedObject var store: PresetStore
    let agent: AgentKind

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let selectedID = store.selectedPresetID(for: agent),
               let binding = store.binding(for: selectedID) {
                PresetEditorView(store: store, preset: binding)
            } else {
                ContentUnavailableView("No Preset Selected", systemImage: agent.systemImage)
            }
        }
        .navigationSplitViewColumnWidth(min: 260, ideal: 300)
    }

    private var sidebar: some View {
        List(selection: store.selectionBinding(for: agent)) {
            Section {
                ForEach(store.presets(for: agent)) { preset in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.name)
                            .font(.headline)
                        Text(preset.model)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(preset.baseURL)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    .tag(preset.id)
                    .padding(.vertical, 4)
                }
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(agent.title)
                    Text(agent.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.addPreset(for: agent)
                } label: {
                    Label("Add", systemImage: "plus")
                }

                Button {
                    store.duplicateSelection(for: agent)
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }

                Button(role: .destructive) {
                    store.deleteSelection(for: agent)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

private struct PresetEditorView: View {
    @ObservedObject var store: PresetStore
    @Binding var preset: ProviderPreset

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryCard
                formCard
                notesCard
                actionCard
            }
            .padding(20)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var summaryCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: preset.agentKind.systemImage)
                        .font(.system(size: 28))
                        .foregroundStyle(accentColor)
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Preset name", text: $preset.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .textFieldStyle(.plain)
                        Text(preset.agentKind.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                HStack(spacing: 14) {
                    summaryPill(title: "Base URL", value: preset.baseURL.isBlank ? "Not set" : preset.baseURL)
                    summaryPill(title: "Model", value: preset.model.isBlank ? "Not set" : preset.model)
                    summaryPill(title: "Auth", value: preset.agentKind == .codex ? preset.codexAuthMode.title : "Anthropic env")
                }
            }
            .padding(6)
        } label: {
            Label("Current Preset", systemImage: "slider.horizontal.3")
        }
    }

    private var formCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 18) {
                Group {
                    TextField("Base URL", text: $preset.baseURL)
                    SecureField("API Key", text: $preset.apiKey)
                    TextField("Model", text: $preset.model)
                }
                .textFieldStyle(.roundedBorder)

                if preset.agentKind == .codex {
                    Divider()
                    codexFields
                } else {
                    Divider()
                    claudeFields
                }
            }
            .padding(6)
        } label: {
            Label("Configuration", systemImage: "gearshape.2")
        }
    }

    @ViewBuilder
    private var codexFields: some View {
        Picker("Auth header", selection: $preset.codexAuthMode) {
            ForEach(CodexAuthMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        if preset.codexAuthMode == .custom {
            TextField("Custom header name", text: $preset.codexCustomHeaderName)
                .textFieldStyle(.roundedBorder)
        }

        TextField("Wire API", text: $preset.codexWireAPI)
            .textFieldStyle(.roundedBorder)

        VStack(alignment: .leading, spacing: 6) {
            Text("Query parameters")
                .font(.headline)
            TextEditor(text: $preset.codexQueryParameters)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 90)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Text("每行一个 `key=value`，例如 `api-version=2025-04-01-preview`。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text("Extra headers")
                .font(.headline)
            TextEditor(text: $preset.codexExtraHeaders)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 110)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Text("每行一个 `Header=Value`。API key header 会在应用时自动补进去。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var claudeFields: some View {
        Stepper(value: $preset.claudeTimeoutMilliseconds, in: 1_000...900_000, step: 1_000) {
            Text("Timeout: \(preset.claudeTimeoutMilliseconds) ms")
        }

        TextField("CA certificate path (optional)", text: $preset.claudeCACertificatePath)
            .textFieldStyle(.roundedBorder)

        VStack(alignment: .leading, spacing: 6) {
            Text("Extra env")
                .font(.headline)
            TextEditor(text: $preset.claudeExtraEnv)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 130)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Text("每行一个 `KEY=VALUE`。会和 `ANTHROPIC_BASE_URL` / `ANTHROPIC_MODEL` 一起写入。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var notesCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.headline)
                TextEditor(text: $preset.notes)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            }
            .padding(6)
        } label: {
            Label("Notes", systemImage: "note.text")
        }
    }

    private var actionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button("Apply to Xcode") {
                        applyCurrentPreset()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reveal Config File") {
                        XcodeAgentConfigurator.revealConfiguration(for: preset.agentKind)
                        store.updateStatus(.init(kind: .info, message: "已在 Finder 中定位配置文件。"))
                    }
                    .buttonStyle(.bordered)

                    Button("Reset to Official") {
                        resetCurrentAgent()
                    }
                    .buttonStyle(.bordered)
                }

                Text(helpText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(6)
        } label: {
            Label("Actions", systemImage: "wand.and.stars")
        }
    }

    private var accentColor: Color {
        switch preset.agentKind {
        case .claude:
            Color(red: 0.86, green: 0.42, blue: 0.24)
        case .codex:
            Color(red: 0.14, green: 0.44, blue: 0.80)
        }
    }

    private var helpText: String {
        switch preset.agentKind {
        case .claude:
            "Claude 会写入 `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/settings.json`，并设置 `com.apple.dt.Xcode` 的 `IDEChatClaudeAgentAPIKeyOverride` / `IDEChatClaudeAgentModelConfigurationAlias`。"
        case .codex:
            "Codex 会在 `~/Library/Developer/Xcode/CodingAssistant/codex/config.toml` 顶部插入一个受管 block，保留其他已有配置。"
        }
    }

    private func summaryPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func applyCurrentPreset() {
        do {
            let result = try XcodeAgentConfigurator.apply(preset)
            store.updateStatus(.init(kind: .success, message: result.summary))
        } catch {
            store.updateStatus(.init(kind: .error, message: error.localizedDescription))
        }
    }

    private func resetCurrentAgent() {
        do {
            let result = try XcodeAgentConfigurator.reset(agent: preset.agentKind)
            store.updateStatus(.init(kind: .success, message: result.summary))
        } catch {
            store.updateStatus(.init(kind: .error, message: error.localizedDescription))
        }
    }
}

private struct StatusBannerView: View {
    let banner: StatusBanner

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
            Text(banner.message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var iconName: String {
        switch banner.kind {
        case .success:
            "checkmark.circle.fill"
        case .error:
            "xmark.octagon.fill"
        case .info:
            "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch banner.kind {
        case .success:
            .green
        case .error:
            .red
        case .info:
            .blue
        }
    }

    private var backgroundColor: Color {
        switch banner.kind {
        case .success:
            Color.green.opacity(0.12)
        case .error:
            Color.red.opacity(0.12)
        case .info:
            Color.blue.opacity(0.12)
        }
    }
}
