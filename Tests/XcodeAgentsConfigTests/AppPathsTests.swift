import Foundation
import Testing
@testable import XcodeAgentsConfig

struct AppPathsTests {
    @Test
    func migratesLegacyPresetsIntoNewAppSupportDirectory() throws {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: tempDirectory) }

        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let legacyURL = AppPaths.legacyStateURL(appSupportDirectory: tempDirectory)
        try fileManager.createDirectory(at: legacyURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{\"presets\":[]}".utf8).write(to: legacyURL)

        let migratedURL = AppPaths.stateURL(appSupportDirectory: tempDirectory, fileManager: fileManager)

        #expect(migratedURL.path(percentEncoded: false).contains(AppMetadata.displayName))
        #expect(fileManager.fileExists(atPath: migratedURL.path(percentEncoded: false)))

        let migratedData = try Data(contentsOf: migratedURL)
        #expect(String(decoding: migratedData, as: UTF8.self) == "{\"presets\":[]}")
    }
}
