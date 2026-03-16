import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct KXcodeAgentsConfigApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PresetStore()

    var body: some Scene {
        WindowGroup(AppMetadata.displayName) {
            ContentView(store: store)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1180, height: 820)
    }
}
