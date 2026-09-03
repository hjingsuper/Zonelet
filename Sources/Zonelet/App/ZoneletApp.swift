import AppKit
import OSLog
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.hjingsuper.ZoneletApp",
        category: "Lifecycle"
    )
    private var store: ClockStore?
    private var languageStore: LanguageStore?
    private var launchAtLoginManager: LaunchAtLoginManager?
    private var statusBarController: StatusBarController?
    private var updateManager: UpdateManager?
    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.notice("Application finished launching")

        migratePreferencesFromLegacyBundleIdentifiersIfNeeded()

        let languageStore = LanguageStore()
        let store = ClockStore()
        let launchAtLoginManager = LaunchAtLoginManager()
        let updateManager = UpdateManager()
        self.languageStore = languageStore
        self.store = store
        self.launchAtLoginManager = launchAtLoginManager
        self.updateManager = updateManager
        let statusBarController = StatusBarController(
            store: store,
            languageStore: languageStore,
            openSettings: { [weak self] in
                self?.showWindow()
            },
            updatesAvailable: updateManager.isAvailable,
            checkForUpdates: { [weak updateManager] in
                updateManager?.checkForUpdates()
            }
        )
        self.statusBarController = statusBarController
        updateManager.onGentleUpdateAvailabilityChanged = { [weak statusBarController] isAvailable in
            statusBarController?.setGentleUpdateReminderVisible(isAvailable)
        }
        logger.notice("Application services are ready")
        updateManager.start()

#if DEBUG
        if ProcessInfo.processInfo.environment["ZONELET_UI_PREVIEW"] == "1" {
            showWindow()
        }
#endif
    }

    private func migratePreferencesFromLegacyBundleIdentifiersIfNeeded() {
        let defaults = UserDefaults.standard
        let migrationKey = "zonelet.did-migrate-preferences-v3"
        guard !defaults.bool(forKey: migrationKey) else { return }

        let currentIdentifier = Bundle.main.bundleIdentifier
        let legacyIdentifiers = [
            "com.hjingsuper.Zonelet",
            "com.local.Zonelet",
        ]
        let migratableKeys: Set<String> = [
            "zonelet.clocks",
            "zonelet.display-format",
            "zonelet.language",
            "zonelet.launch-at-login",
        ]

        for identifier in legacyIdentifiers where identifier != currentIdentifier {
            if let legacy = defaults.persistentDomain(forName: identifier) {
                for (key, value) in legacy
                    where migratableKeys.contains(key) && defaults.object(forKey: key) == nil
                {
                    defaults.set(value, forKey: key)
                }
                logger.notice("Migrated preferences from \(identifier, privacy: .public)")
            }
        }

        defaults.set(true, forKey: migrationKey)
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
            window.setContentSize(NSSize(width: 1040, height: 560))
            window.contentMinSize = NSSize(width: 980, height: 470)
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
@MainActor
enum ZoneletApp {
    static func main() {
        let application = NSApplication.shared
        let appDelegate = AppDelegate()
        application.delegate = appDelegate
        application.run()

        // NSApplication's delegate is not an ownership boundary. Keeping the
        // local reference alive for the duration of run() makes that lifetime
        // explicit without introducing global application state.
        _ = appDelegate
    }
}
