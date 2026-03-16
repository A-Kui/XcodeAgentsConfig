import Foundation

enum AppMetadata {
    static let displayName = "kXcodeAgentsConfig"
    static let legacyDisplayName = "XcodeAgentsConfig"
    static let bundleIdentifier = "com.k.kXcodeAgentsConfig"
    static let version = "1.0"
    static let build = "1.0"
}

enum AppPaths {
    static let presetsFileName = "presets.json"

    static func stateURL(fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return stateURL(appSupportDirectory: appSupport, fileManager: fileManager)
    }

    static func stateURL(appSupportDirectory: URL, fileManager: FileManager = .default) -> URL {
        let directory = appSupportDirectory.appendingPathComponent(AppMetadata.displayName, isDirectory: true)
        let stateURL = directory.appendingPathComponent(presetsFileName, isDirectory: false)
        migrateLegacyPresetFileIfNeeded(to: stateURL, appSupportDirectory: appSupportDirectory, fileManager: fileManager)
        return stateURL
    }

    static func legacyStateURL(appSupportDirectory: URL) -> URL {
        appSupportDirectory
            .appendingPathComponent(AppMetadata.legacyDisplayName, isDirectory: true)
            .appendingPathComponent(presetsFileName, isDirectory: false)
    }

    private static func migrateLegacyPresetFileIfNeeded(to stateURL: URL, appSupportDirectory: URL, fileManager: FileManager) {
        let statePath = stateURL.path(percentEncoded: false)
        guard !fileManager.fileExists(atPath: statePath) else {
            return
        }

        let legacyURL = legacyStateURL(appSupportDirectory: appSupportDirectory)
        let legacyPath = legacyURL.path(percentEncoded: false)
        guard fileManager.fileExists(atPath: legacyPath) else {
            return
        }

        do {
            try fileManager.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try fileManager.copyItem(at: legacyURL, to: stateURL)
        } catch {
            // If the copy fails we still fall back to the new path and let the app recreate defaults.
        }
    }
}
