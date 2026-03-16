# Repository Guidelines

## Project Structure & Module Organization
- `Package.swift` defines a single SwiftPM executable target for a macOS 14+ SwiftUI app.
- App source lives in `Sources/XcodeAgentsConfig/`.
- `XcodeAgentsConfigApp.swift` boots the app, `ContentView.swift` contains the main UI, and supporting models and persistence logic live in files such as `Models.swift`, `PresetStore.swift`, and `XcodeAgentConfigurator.swift`.
- `README.md` documents product behavior and local Xcode integration paths. There is currently no `Tests/` directory.

## Build, Test, and Development Commands
- `swift run` builds and launches the app from the repository root.
- `swift build` checks that the package compiles without launching the UI.
- `swift package resolve` refreshes package metadata if Xcode or SwiftPM gets out of sync.
- You can also open `Package.swift` directly in Xcode for interactive development and previews.

## Coding Style & Naming Conventions
- Follow standard Swift style with 4-space indentation and no force unwrapping unless unavoidable.
- Use `PascalCase` for types, `camelCase` for properties and methods, and clear enum case names such as `claude` and `codex`.
- Keep SwiftUI views focused: UI in `body`, state in `@State` or `@StateObject`, shared observable state in store types.
- Prefer small, purpose-driven files and extend existing models or stores instead of duplicating configuration logic.

## Testing Guidelines
- Add tests with Apple’s `Testing` framework when introducing non-trivial model, parsing, or file-writing logic.
- Place future tests under `Tests/XcodeAgentsConfigTests/` and name them after the unit under test, for example `PresetStoreTests.swift`.
- Run `swift test` for automated checks once a test target exists; until then, validate changes with `swift build` and focused manual app flows.

## Commit & Pull Request Guidelines
- The current history is minimal (`Initial commit`), so use short, imperative commit subjects such as `Add codex header validation`.
- Keep commits scoped to one change and include a brief body when behavior or migration details need context.
- PRs should summarize user-visible changes, list validation performed, and include screenshots for SwiftUI UI changes.
- Link related issues or notes about Xcode-specific behavior when a change touches local config paths or agent integration.

## Configuration Notes
- This app writes to local Xcode assistant config locations; avoid committing secrets, API keys, or machine-specific generated files.
- Treat `.swiftpm/` and build artifacts as local development state unless a specific change requires them.
