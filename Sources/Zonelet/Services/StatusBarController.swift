import AppKit

@MainActor
final class StatusBarController: NSObject {
    init(
        store: ClockStore,
        languageStore: LanguageStore,
        openSettings: @escaping () -> Void
    ) {
        self.store = store
        self.languageStore = languageStore
        self.openSettings = openSettings
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
    private let openSettings: () -> Void
    private var clockItems: [UUID: NSStatusItem] = [:]
    private var timer: Timer?

    private func rebuildClocks() {
        clockItems.values.forEach(NSStatusBar.system.removeStatusItem)
        clockItems.removeAll()

        // New status items are inserted to the left, so build in reverse to
        // preserve the order shown in the manager window.
        let visibleClocks = store.clocks.filter(\.isVisible)
        for clock in visibleClocks.reversed() {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            item.button?.title = ClockPresentation.statusTitle(
                for: clock,
                isLast: clock.id == visibleClocks.last?.id
            )
            item.button?.toolTip = clock.timeZoneIdentifier
            item.menu = makeMenu(for: clock)
            clockItems[clock.id] = item
        }
    }

    private func updateTimes() {
        let now = Date()
        let lastVisibleID = store.clocks.last(where: \.isVisible)?.id
        for (id, item) in clockItems {
            guard let clock = store.clock(id: id) else { continue }
            item.button?.title = ClockPresentation.statusTitle(
                for: clock,
                at: now,
                isLast: clock.id == lastVisibleID
            )
            item.menu = makeMenu(for: clock, at: now)
        }
    }

    private func makeMenu(for clock: ZoneClock, at date: Date = .now) -> NSMenu {
        let menu = NSMenu()
        let heading = NSMenuItem(
            title: "\(TimeZoneCatalog.cityName(for: clock.timeZoneIdentifier, language: languageStore.language)) · \(TimeZoneCatalog.gmtOffset(for: clock.timeZone, at: date))",
            action: nil,
            keyEquivalent: ""
        )
        heading.isEnabled = false
        menu.addItem(heading)
        menu.addItem(.separator())

        let hide = NSMenuItem(title: languageStore[.hideFromMenuBar], action: #selector(hideClock(_:)), keyEquivalent: "")
        hide.target = self
        hide.representedObject = clock.id.uuidString
        menu.addItem(hide)

        menu.addItem(.separator())
        let settings = NSMenuItem(title: languageStore[.manageClocks], action: #selector(openZonelet), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

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
        clockItems.values.forEach(NSStatusBar.system.removeStatusItem)
    }
}
