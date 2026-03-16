import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: PresetStore
    @State private var showRestartXcodeConfirmation = false
    @State private var isRestartingXcode = false

    private var strings: AppStrings {
        AppStrings(language: store.selectedLanguage)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $store.selectedAgent) {
                AgentWorkspaceView(store: store, agent: .claude)
                    .tabItem {
                        Label(AgentKind.claude.title(in: store.selectedLanguage), systemImage: AgentKind.claude.systemImage)
                    }
                    .tag(AgentKind.claude)

                AgentWorkspaceView(store: store, agent: .codex)
                    .tabItem {
                        Label(AgentKind.codex.title(in: store.selectedLanguage), systemImage: AgentKind.codex.systemImage)
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
        .environment(\.locale, store.selectedLanguage.locale)
        .alert(strings.restartAlertTitle, isPresented: $showRestartXcodeConfirmation) {
            Button(strings.cancel, role: .cancel) {}
            Button(strings.restartNow, role: .destructive) {
                restartXcode()
            }
            .disabled(isRestartingXcode)
        } message: {
            Text(strings.restartAlertMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppMetadata.displayName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text(strings.appSubtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text(strings.languageLabel)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))

                    Picker(strings.languageLabel, selection: $store.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 6) {
                    headerLink(for: .claude)
                    headerLink(for: .codex)

                    headerActionLink(
                        title: strings.restartRecommendationTitle,
                        systemImage: "arrow.clockwise.circle.fill",
                        help: strings.restartRecommendationHelp
                    ) {
                        showRestartXcodeConfirmation = true
                    }
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            }
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
        store.updateStatus(.init(kind: .info, message: strings.revealConfigurationStatus(for: agent)))
    }

    @ViewBuilder
    private func headerLink(for agent: AgentKind) -> some View {
        headerActionLink(
            title: strings.headerLinkTitle(for: agent),
            systemImage: "link.circle.fill",
            help: strings.revealConfigurationHelp(for: agent)
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

        let language = store.selectedLanguage
        let strings = AppStrings(language: language)

        isRestartingXcode = true
        store.updateStatus(.init(kind: .info, message: strings.restartInProgress))

        Task {
            do {
                try await XcodeAgentConfigurator.restartXcode(language: language)
                await MainActor.run {
                    isRestartingXcode = false
                    store.updateStatus(.init(kind: .success, message: strings.restartSucceeded))
                }
            } catch {
                await MainActor.run {
                    isRestartingXcode = false
                    store.updateStatus(.init(kind: .error, message: language.message(for: error)))
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

    private var strings: AppStrings {
        AppStrings(language: store.selectedLanguage)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let selectedID = store.selectedPresetID(for: agent),
               let binding = store.binding(for: selectedID) {
                PresetEditorView(store: store, preset: binding)
            } else {
                ContentUnavailableView(strings.noPresetSelected, systemImage: agent.systemImage)
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
                    Text(agent.title(in: store.selectedLanguage))
                    Text(agent.subtitle(in: store.selectedLanguage))
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
                    Label(strings.add, systemImage: "plus")
                }

                Button {
                    store.duplicateSelection(for: agent)
                } label: {
                    Label(strings.duplicate, systemImage: "plus.square.on.square")
                }

                Button(role: .destructive) {
                    store.deleteSelection(for: agent)
                } label: {
                    Label(strings.delete, systemImage: "trash")
                }
            }
        }
    }
}

private struct PresetEditorView: View {
    @ObservedObject var store: PresetStore
    @Binding var preset: ProviderPreset

    private var strings: AppStrings {
        AppStrings(language: store.selectedLanguage)
    }

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
                        TextField(strings.presetNamePlaceholder, text: $preset.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .textFieldStyle(.plain)
                        Text(preset.agentKind.title(in: store.selectedLanguage))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider()

                HStack(spacing: 14) {
                    summaryPill(title: strings.baseURL, value: preset.baseURL.isBlank ? strings.notSet : preset.baseURL)
                    summaryPill(title: strings.model, value: preset.model.isBlank ? strings.notSet : preset.model)
                    summaryPill(
                        title: strings.auth,
                        value: preset.agentKind == .codex ? preset.codexAuthMode.title(in: store.selectedLanguage) : strings.anthropicEnv
                    )
                }
            }
            .padding(6)
        } label: {
            Label(strings.currentPreset, systemImage: "slider.horizontal.3")
        }
    }

    private var formCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 18) {
                Group {
                    TextField(strings.baseURL, text: $preset.baseURL)
                    SecureField(strings.apiKey, text: $preset.apiKey)
                    TextField(strings.model, text: $preset.model)
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
            Label(strings.configuration, systemImage: "gearshape.2")
        }
    }

    @ViewBuilder
    private var codexFields: some View {
        Picker(strings.authHeader, selection: $preset.codexAuthMode) {
            ForEach(CodexAuthMode.allCases) { mode in
                Text(mode.title(in: store.selectedLanguage)).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        if preset.codexAuthMode == .custom {
            TextField(strings.customHeaderName, text: $preset.codexCustomHeaderName)
                .textFieldStyle(.roundedBorder)
        }

        TextField(strings.wireAPI, text: $preset.codexWireAPI)
            .textFieldStyle(.roundedBorder)

        VStack(alignment: .leading, spacing: 6) {
            Text(strings.queryParameters)
                .font(.headline)
            TextEditor(text: $preset.codexQueryParameters)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 90)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Text(strings.queryParametersHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        VStack(alignment: .leading, spacing: 6) {
            Text(strings.extraHeaders)
                .font(.headline)
            TextEditor(text: $preset.codexExtraHeaders)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 110)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Text(strings.extraHeadersHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var claudeFields: some View {
        Stepper(value: $preset.claudeTimeoutMilliseconds, in: 1_000...900_000, step: 1_000) {
            Text(strings.timeout(preset.claudeTimeoutMilliseconds))
        }

        TextField(strings.caCertificatePathOptional, text: $preset.claudeCACertificatePath)
            .textFieldStyle(.roundedBorder)

        VStack(alignment: .leading, spacing: 6) {
            Text(strings.extraEnv)
                .font(.headline)
            TextEditor(text: $preset.claudeExtraEnv)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 130)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Text(strings.extraEnvHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var notesCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text(strings.notes)
                    .font(.headline)
                TextEditor(text: $preset.notes)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            }
            .padding(6)
        } label: {
            Label(strings.notes, systemImage: "note.text")
        }
    }

    private var actionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button(strings.applyToXcode) {
                        applyCurrentPreset()
                    }
                    .buttonStyle(.borderedProminent)

                    Button(strings.revealConfigFile) {
                        XcodeAgentConfigurator.revealConfiguration(for: preset.agentKind)
                        store.updateStatus(.init(kind: .info, message: strings.revealConfigFileStatus))
                    }
                    .buttonStyle(.bordered)

                    Button(strings.resetToOfficial) {
                        resetCurrentAgent()
                    }
                    .buttonStyle(.bordered)
                }

                Text(strings.helpText(for: preset.agentKind))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(6)
        } label: {
            Label(strings.actions, systemImage: "wand.and.stars")
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
        let language = store.selectedLanguage

        do {
            let result = try XcodeAgentConfigurator.apply(preset, language: language)
            store.updateStatus(.init(kind: .success, message: result.summary))
        } catch {
            store.updateStatus(.init(kind: .error, message: language.message(for: error)))
        }
    }

    private func resetCurrentAgent() {
        let language = store.selectedLanguage

        do {
            let result = try XcodeAgentConfigurator.reset(agent: preset.agentKind, language: language)
            store.updateStatus(.init(kind: .success, message: result.summary))
        } catch {
            store.updateStatus(.init(kind: .error, message: language.message(for: error)))
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
