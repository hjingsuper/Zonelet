import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ClockStore {
    private enum Keys {
        static let clocks = "zonelet.clocks"
        static let corruptClocksBackup = "zonelet.clocks.corrupt-backup"
        static let legacyDisplayFormat = "zonelet.display-format"
    }

    private(set) var clocks: [ZoneClock] = []
    private(set) var defaultDisplayFormat: DisplayFormatPreset
    private(set) var recoveredConfiguration = false
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedPattern = defaults.string(forKey: Keys.legacyDisplayFormat)
        defaultDisplayFormat = DisplayFormatPreset.allCases.first { $0.pattern == savedPattern } ?? .time24

        if let data = defaults.data(forKey: Keys.clocks) {
            do {
                let decodedClocks = try JSONDecoder().decode([ZoneClock].self, from: data)
                let normalized = normalize(decodedClocks)
                let containsLegacyLabels = Self.containsLegacyLabels(in: data)
                clocks = normalized.clocks
                if normalized.didRepair {
                    backUpAndReportRecovery(data)
                }
                if normalized.didRepair || containsLegacyLabels {
                    persist()
                }
            } catch {
                clocks = [Self.defaultClock(displayFormat: defaultDisplayFormat)]
                backUpAndReportRecovery(data)
                logger.error("Clock configuration was unreadable and has been backed up: \(error.localizedDescription, privacy: .public)")
                persist()
            }
        } else {
            clocks = [Self.defaultClock(displayFormat: defaultDisplayFormat)]
            persist()
        }
    }

    func add(timeZoneIdentifier: String) {
        guard TimeZone(identifier: timeZoneIdentifier) != nil else { return }
        guard !clocks.contains(where: { $0.timeZoneIdentifier == timeZoneIdentifier }) else { return }
        clocks.append(
            ZoneClock(
                timeZoneIdentifier: timeZoneIdentifier,
                displayFormat: defaultDisplayFormat
            )
        )
        changed()
    }

    func remove(id: UUID) {
        clocks.removeAll { $0.id == id }
        changed()
    }

    func setVisible(id: UUID, _ isVisible: Bool) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        clocks[index].isVisible = isVisible
        changed()
    }

    func setDisplayFormat(id: UUID, _ preset: DisplayFormatPreset) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        guard clocks[index].displayFormatPattern != preset.pattern else { return }
        clocks[index].displayFormatPattern = preset.pattern
        changed()
    }

    func setDisplayFormatForAll(_ preset: DisplayFormatPreset) {
        defaultDisplayFormat = preset
        defaults.set(preset.pattern, forKey: Keys.legacyDisplayFormat)
        for index in clocks.indices {
            clocks[index].displayFormatPattern = preset.pattern
        }
        changed()
    }

    var uniformDisplayFormat: DisplayFormatPreset? {
        guard let first = clocks.first?.displayFormatPreset else { return defaultDisplayFormat }
        return clocks.dropFirst().allSatisfy { $0.displayFormatPreset == first } ? first : nil
    }

    func move(id: UUID, relativeTo targetID: UUID, insertAfter: Bool) {
        guard
            id != targetID,
            let sourceIndex = clocks.firstIndex(where: { $0.id == id })
        else { return }

        let movingClock = clocks.remove(at: sourceIndex)
        guard let targetIndex = clocks.firstIndex(where: { $0.id == targetID }) else {
            clocks.insert(movingClock, at: sourceIndex)
            return
        }

        let insertionIndex = insertAfter ? targetIndex + 1 : targetIndex
        clocks.insert(movingClock, at: min(insertionIndex, clocks.count))
        changed()
    }

    func clock(id: UUID) -> ZoneClock? {
        clocks.first { $0.id == id }
    }

    private let defaults: UserDefaults
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.hjingsuper.ZoneletApp",
        category: "ClockStore"
    )

    private static func defaultClock(displayFormat: DisplayFormatPreset) -> ZoneClock {
        ZoneClock(timeZoneIdentifier: "UTC", displayFormat: displayFormat)
    }

    private static func containsLegacyLabels(in data: Data) -> Bool {
        guard let objects = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return false
        }
        return objects.contains { $0["label"] != nil }
    }

    private func normalize(_ decodedClocks: [ZoneClock]) -> (
        clocks: [ZoneClock],
        didRepair: Bool
    ) {
        var didRepair = false
        let knownPatterns = Set(DisplayFormatPreset.allCases.map(\.pattern))
        var normalizedClocks: [ZoneClock] = []
        var seenClockIDs: Set<UUID> = []
        var seenTimeZones: Set<String> = []

        for var clock in decodedClocks {
            guard TimeZone(identifier: clock.timeZoneIdentifier) != nil else {
                didRepair = true
                continue
            }
            guard
                seenClockIDs.insert(clock.id).inserted,
                seenTimeZones.insert(clock.timeZoneIdentifier).inserted
            else {
                didRepair = true
                continue
            }
            if !knownPatterns.contains(clock.displayFormatPattern ?? "") {
                clock.displayFormatPattern = defaultDisplayFormat.pattern
                didRepair = true
            }
            normalizedClocks.append(clock)
        }

        if !decodedClocks.isEmpty, normalizedClocks.isEmpty {
            normalizedClocks = [Self.defaultClock(displayFormat: defaultDisplayFormat)]
        }
        return (normalizedClocks, didRepair)
    }

    private func backUpAndReportRecovery(_ data: Data) {
        defaults.set(data, forKey: Keys.corruptClocksBackup)
        recoveredConfiguration = true
    }

    private func changed() {
        persist()
        onChange?()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(clocks) else { return }
        defaults.set(data, forKey: Keys.clocks)
    }
}
