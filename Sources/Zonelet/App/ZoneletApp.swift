import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var store: ClockStore?
    private var languageStore: LanguageStore?
    private var launchAtLoginManager: LaunchAtLoginManager?
    private var statusBarController: StatusBarController?
    private var updateManager: UpdateManager?
    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let languageStore = LanguageStore()
        let store = ClockStore(languageStore: languageStore)
        let launchAtLoginManager = LaunchAtLoginManager()
        let updateManager = UpdateManager()
        self.languageStore = languageStore
        self.store = store
        self.launchAtLoginManager = launchAtLoginManager
        self.updateManager = updateManager
        statusBarController = StatusBarController(
            store: store,
            languageStore: languageStore
        ) { [weak self] in
            self?.showWindow()
        } checkForUpdates: { [weak updateManager] in
            updateManager?.checkForUpdates()
        }
        updateManager.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showWindow()
        return true
    }

    private func showWindow() {
        guard
            let store,
            let languageStore,
            let launchAtLoginManager,
            let updateManager
        else { return }

        if windowController == nil {
            let rootView = ClockListView(
                store: store,
                languageStore: languageStore,
                launchAtLoginManager: launchAtLoginManager,
                updateManager: updateManager
            )
            let hostingController = NSHostingController(rootView: rootView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "Zonelet"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 620, height: 560))
            window.minSize = NSSize(width: 560, height: 460)
            window.isReleasedWhenClosed = false
            window.center()
            windowController = NSWindowController(window: window)
        }

        NSApp.activate(ignoringOtherApps: true)
        windowController?.showWindow(nil)
        windowController?.window?.makeKeyAndOrderFront(nil)
    }
}

@main
struct ZoneletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
