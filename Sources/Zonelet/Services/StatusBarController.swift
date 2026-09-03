import AppKit
import OSLog
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    init(
        store: ClockStore,
        languageStore: LanguageStore,
        openSettings: @escaping () -> Void,
        updatesAvailable: Bool,
        checkForUpdates: @escaping () -> Void
    ) {
        self.store = store
        self.languageStore = languageStore
        self.openSettings = openSettings
        self.updatesAvailable = updatesAvailable
        self.checkForUpdates = checkForUpdates
        super.init()

        menu.delegate = self

        store.onChange = { [weak self] in
            self?.rebuildClocks()
        }
        languageStore.onChange = { [weak self] in
            self?.rebuildClocks()
        }
        // On macOS 26 the Control Center status-item host may still be
        // reconnecting while applicationDidFinishLaunching is running,
        // especially with more than one display. Creating the item on the
        // next settled main-loop turn avoids producing a visible-but-unhosted
        // NSStatusItem scene.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.rebuildClocks()
        }
    }

    private let store: ClockStore
    private let languageStore: LanguageStore
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.hjingsuper.ZoneletApp",
        category: "MenuBar"
    )
    private let openSettings: () -> Void
    private let updatesAvailable: Bool
    private let checkForUpdates: () -> Void
    private let menu = NSMenu()
    private var statusItem: NSStatusItem?
    private var timer: Timer?
    private var hasGentleUpdateReminder = false

    private func rebuildClocks() {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            // A stable autosave name keeps macOS from creating a new hidden
            // Control Center entry whenever the app path or build changes.
            item.autosaveName = "com.hjingsuper.ZoneletApp.primary-status-item"
            item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            item.button?.image = nil
            item.button?.imagePosition = .noImage
            item.menu = menu
            item.isVisible = true
            statusItem = item
            logger.notice("Created status item with a stable persisted identity")
        }

        updateStatusItem(shouldRebuildMenu: true)
        scheduleTimer()
    }

    private func updateTimes() {
        updateStatusItem(at: .now, shouldRebuildMenu: false)
    }

    private func updateStatusItem(at date: Date = .now, shouldRebuildMenu: Bool) {
        guard let statusItem else { return }
        let visibleClocks = store.clocks.filter(\.isVisible)
        let title = ClockPresentation.statusTitle(
            for: visibleClocks,
            at: date,
            language: languageStore.language,
            maxLength: hasGentleUpdateReminder ? 46 : 48
        )
        statusItem.button?.title = hasGentleUpdateReminder ? "\(title) •" : title
        statusItem.button?.toolTip = visibleClocks.isEmpty
            ? "Zonelet"
            : visibleClocks
                .map {
                    TimeZoneCatalog.cityName(
                        for: $0.timeZoneIdentifier,
                        language: languageStore.language
                    )
                }
                .joined(separator: " · ")
        if shouldRebuildMenu {
            rebuildMenu(for: visibleClocks, at: date)
        }
        statusItem.isVisible = true
        if shouldRebuildMenu {
            logger.debug(
                "Updated status item: visible=\(statusItem.isVisible), clocks=\(visibleClocks.count), title=\(statusItem.button?.title ?? "", privacy: .public)"
            )
        }
    }

    private func rebuildMenu(for clocks: [ZoneClock], at date: Date = .now) {
        menu.removeAllItems()
        if clocks.isEmpty {
            let heading = NSMenuItem(title: "Zonelet", action: nil, keyEquivalent: "")
            heading.isEnabled = false
            menu.addItem(heading)
        } else {
            menu.addItem(
                viewMenuItem(
                    rootView: StatusClockMenuHeaderView(languageStore: languageStore),
                    height: 24
                )
            )
            menu.addItem(.separator())

            for (index, clock) in clocks.enumerated() {
                menu.addItem(
                    viewMenuItem(
                        rootView: StatusClockMenuRowView(
                            clock: clock,
                            date: date,
                            languageStore: languageStore,
                            showsDivider: index < clocks.count - 1
                        ),
                        height: 34
                    )
                )
            }
        }

        menu.addItem(.separator())
        let settings = NSMenuItem(title: languageStore[.manageClocks], action: #selector(openZonelet), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let updates = NSMenuItem(
            title: languageStore[
                hasGentleUpdateReminder ? .updateAvailable : .checkForUpdates
            ],
            action: #selector(checkForUpdatesNow),
            keyEquivalent: ""
        )
        updates.target = self
        updates.isEnabled = updatesAvailable
        menu.addItem(updates)

        let source = NSMenuItem(title: languageStore[.sourceOnGitHub], action: #selector(openSource), keyEquivalent: "")
        source.target = self
        menu.addItem(source)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: languageStore[.quitApp], action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func scheduleTimer() {
        timer?.invalidate()
        timer = nil

        let visibleClocks = store.clocks.filter(\.isVisible)
        guard !visibleClocks.isEmpty else { return }

        let interval = ClockRefreshPolicy.interval(for: visibleClocks)
        let now = Date()
        let nextBoundary = ClockRefreshPolicy.nextFireDate(after: now, interval: interval)
        let newTimer = Timer(
            fireAt: nextBoundary,
            interval: interval,
            target: self,
            selector: #selector(timerDidFire),
            userInfo: nil,
            repeats: true
        )
        newTimer.tolerance = interval == 1 ? 0.05 : 0.5
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    @objc private func timerDidFire() {
        updateTimes()
    }

    func menuWillOpen(_ menu: NSMenu) {
        logger.debug("Status menu will open")
        rebuildMenu(for: store.clocks.filter(\.isVisible), at: .now)
    }

    func setGentleUpdateReminderVisible(_ isVisible: Bool) {
        guard hasGentleUpdateReminder != isVisible else { return }
        hasGentleUpdateReminder = isVisible
        updateStatusItem(shouldRebuildMenu: true)
    }

    @objc private func openZonelet() {
        openSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    @objc private func checkForUpdatesNow() {
        checkForUpdates()
    }

    @objc private func openSource() {
        guard let url = URL(string: "https://github.com/hjingsuper/Zonelet") else { return }
        NSWorkspace.shared.open(url)
    }

    private func viewMenuItem<Content: View>(rootView: Content, height: CGFloat) -> NSMenuItem {
        let item = NSMenuItem()
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(
            x: 0,
            y: 0,
            width: StatusClockMenuLayout.width,
            height: height
        )
        item.view = hostingView
        return item
    }

    deinit {
        timer?.invalidate()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
