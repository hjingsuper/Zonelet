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
        static let defaultCustomDisplayFormat = "zonelet.custom-display-format"
    }

    private(set) var clocks: [ZoneClock] = []
    private(set) var defaultDisplayFormat: DisplayFormatPreset
    private(set) var defaultCustomDisplayFormat: CustomDisplayFormat?
    private(set) var recoveredConfiguration = false
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedPattern = defaults.string(forKey: Keys.legacyDisplayFormat)
        defaultDisplayFormat = DisplayFormatPreset.allCases.first { $0.pattern == savedPattern } ?? .time24
        defaultCustomDisplayFormat = defaults.data(forKey: Keys.defaultCustomDisplayFormat)
            .flatMap { try? JSONDecoder().decode(CustomDisplayFormat.self, from: $0) }

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
                clocks = [defaultClock()]
                backUpAndReportRecovery(data)
                logger.error("Clock configuration was unreadable and has been backed up: \(error.localizedDescription, privacy: .public)")
                persist()
            }
        } else {
            clocks = [defaultClock()]
            persist()
        }
    }

    func add(timeZoneIdentifier: String) {
        guard TimeZone(identifier: timeZoneIdentifier) != nil else { return }
        guard !clocks.contains(where: { $0.timeZoneIdentifier == timeZoneIdentifier }) else { return }
        if let defaultCustomDisplayFormat {
            clocks.append(
                ZoneClock(
                    timeZoneIdentifier: timeZoneIdentifier,
                    customDisplayFormat: defaultCustomDisplayFormat
                )
            )
        } else {
            clocks.append(
                ZoneClock(
                    timeZoneIdentifier: timeZoneIdentifier,
                    displayFormat: defaultDisplayFormat
                )
            )
        }
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
        clocks[index].apply(displayFormat: preset)
        changed()
    }

    func setCustomDisplayFormat(id: UUID, _ format: CustomDisplayFormat) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        guard clocks[index].customDisplayFormat != format else { return }
        clocks[index].apply(customDisplayFormat: format)
        changed()
    }

    func setDisplayFormatForAll(_ preset: DisplayFormatPreset) {
        defaultDisplayFormat = preset
        defaultCustomDisplayFormat = nil
        defaults.set(preset.pattern, forKey: Keys.legacyDisplayFormat)
        defaults.removeObject(forKey: Keys.defaultCustomDisplayFormat)
        for index in clocks.indices {
            clocks[index].apply(displayFormat: preset)
        }
        changed()
    }

    func setCustomDisplayFormatForAll(_ format: CustomDisplayFormat) {
        defaultCustomDisplayFormat = format
        defaults.set(format.pattern, forKey: Keys.legacyDisplayFormat)
        if let data = try? JSONEncoder().encode(format) {
            defaults.set(data, forKey: Keys.defaultCustomDisplayFormat)
        }
        for index in clocks.indices {
            clocks[index].apply(customDisplayFormat: format)
        }
        changed()
    }

    var uniformDisplayFormat: DisplayFormatPreset? {
        guard let firstClock = clocks.first else {
            return defaultCustomDisplayFormat == nil ? defaultDisplayFormat : nil
        }
        guard let first = firstClock.displayFormatPreset else { return nil }
        return clocks.dropFirst().allSatisfy { $0.displayFormatPreset == first } ? first : nil
    }

    var uniformCustomDisplayFormat: CustomDisplayFormat? {
        guard let firstClock = clocks.first else { return defaultCustomDisplayFormat }
        guard let first = firstClock.customDisplayFormat else { return nil }
        return clocks.dropFirst().allSatisfy { $0.customDisplayFormat == first } ? first : nil
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

    private func defaultClock() -> ZoneClock {
        if let defaultCustomDisplayFormat {
            return ZoneClock(
                timeZoneIdentifier: "UTC",
                customDisplayFormat: defaultCustomDisplayFormat
            )
        }
        return ZoneClock(timeZoneIdentifier: "UTC", displayFormat: defaultDisplayFormat)
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
            let validPreset = clock.customDisplayFormat == nil && clock.displayFormatPreset != nil
            let validCustom = clock.customDisplayFormat.map {
                $0.pattern == clock.displayFormatPattern
            } ?? false
            if !validPreset && !validCustom {
                if let defaultCustomDisplayFormat {
                    clock.apply(customDisplayFormat: defaultCustomDisplayFormat)
                } else {
                    clock.apply(displayFormat: defaultDisplayFormat)
                }
                didRepair = true
            }
            normalizedClocks.append(clock)
        }

        if !decodedClocks.isEmpty, normalizedClocks.isEmpty {
            normalizedClocks = [defaultClock()]
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
