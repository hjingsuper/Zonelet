import Foundation

struct ZoneClock: Codable, Identifiable, Equatable {
    let id: UUID
    var timeZoneIdentifier: String
    var label: String
    var isVisible: Bool
    var displayFormatPattern: String?

    init(
        id: UUID = UUID(),
        timeZoneIdentifier: String,
        label: String,
        isVisible: Bool = true,
        displayFormat: DisplayFormatPreset = .time24
    ) {
        self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier
        self.label = label
        self.isVisible = isVisible
        displayFormatPattern = displayFormat.pattern
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .gmt
    }

    var displayFormatPreset: DisplayFormatPreset {
        DisplayFormatPreset.allCases.first { $0.pattern == displayFormatPattern } ?? .time24
    }

    var effectiveDisplayFormat: String {
        displayFormatPreset.pattern
    }
}
