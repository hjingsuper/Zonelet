import Foundation

struct ZoneClock: Codable, Identifiable, Equatable {
    let id: UUID
    let timeZoneIdentifier: String
    var isVisible: Bool
    var displayFormatPattern: String?

    init(
        id: UUID = UUID(),
        timeZoneIdentifier: String,
        isVisible: Bool = true,
        displayFormat: DisplayFormatPreset = .time24
    ) {
        self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isVisible = isVisible
        displayFormatPattern = displayFormat.pattern
    }

    var timeZone: TimeZone {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            preconditionFailure("ClockStore must remove invalid time-zone identifiers before use")
        }
        return timeZone
    }

    var displayFormatPreset: DisplayFormatPreset {
        guard let preset = DisplayFormatPreset.allCases.first(where: {
            $0.pattern == displayFormatPattern
        }) else {
            preconditionFailure("ClockStore must normalize unknown display formats before use")
        }
        return preset
    }

    var effectiveDisplayFormat: String {
        displayFormatPreset.pattern
    }
}
