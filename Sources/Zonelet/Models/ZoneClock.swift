import Foundation

struct ZoneClock: Codable, Identifiable, Equatable {
    let id: UUID
    let timeZoneIdentifier: String
    var isVisible: Bool
    var displayFormatPattern: String?
    var customDisplayFormat: CustomDisplayFormat?

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
        customDisplayFormat = nil
    }

    init(
        id: UUID = UUID(),
        timeZoneIdentifier: String,
        isVisible: Bool = true,
        customDisplayFormat: CustomDisplayFormat
    ) {
        self.id = id
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isVisible = isVisible
        displayFormatPattern = customDisplayFormat.pattern
        self.customDisplayFormat = customDisplayFormat
    }

    var timeZone: TimeZone {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            preconditionFailure("ClockStore must remove invalid time-zone identifiers before use")
        }
        return timeZone
    }

    var displayFormatPreset: DisplayFormatPreset? {
        guard customDisplayFormat == nil else { return nil }
        return DisplayFormatPreset.allCases.first(where: {
            $0.pattern == displayFormatPattern
        })
    }

    var effectiveDisplayFormat: String {
        customDisplayFormat?.pattern ?? displayFormatPreset?.pattern ?? DisplayFormatPreset.time24.pattern
    }

    mutating func apply(displayFormat preset: DisplayFormatPreset) {
        displayFormatPattern = preset.pattern
        customDisplayFormat = nil
    }

    mutating func apply(customDisplayFormat format: CustomDisplayFormat) {
        displayFormatPattern = format.pattern
        customDisplayFormat = format
    }
}
