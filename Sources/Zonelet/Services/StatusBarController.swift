import AppKit
import OSLog

@MainActor
final class StatusBarController: NSObject {
    init(
        store: ClockStore,
        languageStore: LanguageStore,
        openSettings: @escaping () -> Void,
        checkForUpdates: @escaping () -> Void
    ) {
        self.store = store
        self.languageStore = languageStore
        self.openSettings = openSettings
        self.checkForUpdates = checkForUpdates
        super.init()

        store.onChange = { [weak self] in
            self?.rebuildClocks()
        }
        languageStore.onChange = { [weak self] in
            self?.rebuildClocks()
        }
        rebuildClocks()
        startTimer()
    }

    private let store: ClockStore
    private let languageStore: LanguageStore
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.local.Zonelet",
        category: "MenuBar"
    )
    private let openSettings: () -> Void
    private let checkForUpdates: () -> Void
    private var statusItem: NSStatusItem?
    private var timer: Timer?

    private func rebuildClocks() {
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            item.button?.image = nil
            item.button?.imagePosition = .noImage
            statusItem = item
            logger.notice("Created status item")
        }

        updateStatusItem()
    }

    private func updateTimes() {
        updateStatusItem(at: .now)
    }

    private func updateStatusItem(at date: Date = .now) {
        guard let statusItem else { return }
        let visibleClocks = store.clocks.filter(\.isVisible)
        statusItem.button?.title = ClockPresentation.statusTitle(for: visibleClocks, at: date)
        statusItem.button?.toolTip = visibleClocks.isEmpty
            ? "Zonelet"
            : visibleClocks.map(\.timeZoneIdentifier).joined(separator: " · ")
        statusItem.menu = makeMenu(for: visibleClocks, at: date)
        statusItem.isVisible = true
        logger.debug(
            "Updated status item: visible=\(statusItem.isVisible), clocks=\(visibleClocks.count), title=\(statusItem.button?.title ?? "", privacy: .public)"
        )
    }

    private func makeMenu(for clocks: [ZoneClock], at date: Date = .now) -> NSMenu {
        let menu = NSMenu()
        if clocks.isEmpty {
            let heading = NSMenuItem(title: "Zonelet", action: nil, keyEquivalent: "")
            heading.isEnabled = false
            menu.addItem(heading)
        } else {
            for (index, clock) in clocks.enumerated() {
                let time = ClockPresentation.timeString(
                    at: date,
                    in: clock.timeZone,
                    format: clock.effectiveDisplayFormat
                )
                let heading = NSMenuItem(
                    title: "\(clock.label)  \(time) · \(TimeZoneCatalog.gmtOffset(for: clock.timeZone, at: date))",
                    action: nil,
                    keyEquivalent: ""
                )
                heading.isEnabled = false
                menu.addItem(heading)

                let hide = NSMenuItem(
                    title: languageStore[.hideFromMenuBar],
                    action: #selector(hideClock(_:)),
                    keyEquivalent: ""
                )
                hide.target = self
                hide.representedObject = clock.id.uuidString
                hide.indentationLevel = 1
                menu.addItem(hide)

                if index < clocks.count - 1 {
                    menu.addItem(.separator())
                }
            }
        }

        menu.addItem(.separator())
        let settings = NSMenuItem(title: languageStore[.manageClocks], action: #selector(openZonelet), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let updates = NSMenuItem(
            title: languageStore[.checkForUpdates],
            action: #selector(checkForUpdatesNow),
            keyEquivalent: ""
        )
        updates.target = self
        menu.addItem(updates)

        let source = NSMenuItem(title: languageStore[.sourceOnGitHub], action: #selector(openSource), keyEquivalent: "")
        source.target = self
        menu.addItem(source)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: languageStore[.quitApp], action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 20,
            target: self,
            selector: #selector(timerDidFire),
            userInfo: nil,
            repeats: true
        )
        timer?.tolerance = 2
    }

    @objc private func timerDidFire() {
        updateTimes()
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

    @objc private func hideClock(_ sender: NSMenuItem) {
        guard
            let rawID = sender.representedObject as? String,
            let id = UUID(uuidString: rawID)
        else { return }
        store.setVisible(id: id, false)
    }

    deinit {
        timer?.invalidate()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
    }
}
