import Foundation
import Observation

@MainActor
@Observable
final class ClockStore {
    private enum Keys {
        static let clocks = "zonelet.clocks"
        static let didSeedLima = "zonelet.seed-lima.v1"
        static let legacyDisplayFormat = "zonelet.display-format"
    }

    private(set) var clocks: [ZoneClock] = []
    private(set) var defaultDisplayFormat: DisplayFormatPreset
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard, languageStore: LanguageStore? = nil) {
        self.defaults = defaults
        self.languageStore = languageStore ?? LanguageStore(defaults: defaults)
        let savedPattern = defaults.string(forKey: Keys.legacyDisplayFormat)
        defaultDisplayFormat = DisplayFormatPreset.allCases.first { $0.pattern == savedPattern } ?? .time24

        if
            let data = defaults.data(forKey: Keys.clocks),
            let saved = try? JSONDecoder().decode([ZoneClock].self, from: data)
        {
            clocks = saved
        } else {
            clocks = [
                ZoneClock(timeZoneIdentifier: "UTC", label: "UTC", displayFormat: defaultDisplayFormat),
                ZoneClock(timeZoneIdentifier: "America/Lima", label: "利马", displayFormat: defaultDisplayFormat)
            ]
            defaults.set(true, forKey: Keys.didSeedLima)
            persist()
        }

        seedLimaIfNeeded()
        migrateDisplayFormatsIfNeeded()
    }

    func add(timeZoneIdentifier: String) {
        guard !clocks.contains(where: { $0.timeZoneIdentifier == timeZoneIdentifier }) else { return }
        clocks.append(
            ZoneClock(
                timeZoneIdentifier: timeZoneIdentifier,
                label: TimeZoneCatalog.cityName(
                    for: timeZoneIdentifier,
                    language: languageStore.language
                ),
                displayFormat: defaultDisplayFormat
            )
        )
        changed()
    }

    func remove(id: UUID) {
        clocks.removeAll { $0.id == id }
        changed()
    }

    func rename(id: UUID, to label: String) {
        guard let index = clocks.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = String(label.prefix(18)).trimmingCharacters(in: .whitespacesAndNewlines)
        clocks[index].label = trimmed.isEmpty
            ? TimeZoneCatalog.cityName(
                for: clocks[index].timeZoneIdentifier,
                language: languageStore.language
            )
            : trimmed
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

    func moveUp(id: UUID) {
        guard let index = clocks.firstIndex(where: { $0.id == id }), index > 0 else { return }
        clocks.swapAt(index, index - 1)
        changed()
    }

    func moveDown(id: UUID) {
        guard
            let index = clocks.firstIndex(where: { $0.id == id }),
            index < clocks.count - 1
        else { return }
        clocks.swapAt(index, index + 1)
        changed()
    }

    func clock(id: UUID) -> ZoneClock? {
        clocks.first { $0.id == id }
    }

    private let defaults: UserDefaults
    private let languageStore: LanguageStore

    private func seedLimaIfNeeded() {
        guard !defaults.bool(forKey: Keys.didSeedLima) else { return }
        defer { defaults.set(true, forKey: Keys.didSeedLima) }

        guard !clocks.contains(where: { $0.timeZoneIdentifier == "America/Lima" }) else { return }
        clocks.append(
            ZoneClock(
                timeZoneIdentifier: "America/Lima",
                label: "利马",
                displayFormat: defaultDisplayFormat
            )
        )
        persist()
    }

    private func migrateDisplayFormatsIfNeeded() {
        var didChange = false

        for index in clocks.indices where clocks[index].displayFormatPattern == nil {
            clocks[index].displayFormatPattern = defaultDisplayFormat.pattern
            didChange = true
        }

        if didChange { persist() }
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
