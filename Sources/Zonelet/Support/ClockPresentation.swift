import Foundation

enum ClockPresentation {
    static func timeString(
        at date: Date = .now,
        in timeZone: TimeZone,
        locale: Locale = .current,
        format: String? = nil
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        if let format {
            formatter.dateFormat = format
        } else {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        }
        return formatter.string(from: date)
    }

    static func dayOffset(
        at date: Date = .now,
        from localTimeZone: TimeZone = .current,
        to targetTimeZone: TimeZone
    ) -> Int {
        let localComponents = dayComponents(at: date, in: localTimeZone)
        let targetComponents = dayComponents(at: date, in: targetTimeZone)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = .gmt

        guard
            let localDay = utcCalendar.date(from: localComponents),
            let targetDay = utcCalendar.date(from: targetComponents)
        else {
            return 0
        }

        return utcCalendar.dateComponents([.day], from: localDay, to: targetDay).day ?? 0
    }

    static func menuTitle(
        for clock: ZoneClock,
        at date: Date = .now,
        language: AppLanguage = .english,
        maxLength: Int = 30
    ) -> String {
        let time = timeString(at: date, in: clock.timeZone, format: clock.effectiveDisplayFormat)
        let offset = dayOffset(at: date, to: clock.timeZone)
        let dayMarker = dayMarker(for: offset, language: language)

        let title = "\(clock.label) \(time)\(dayMarker)"
        return title.count <= maxLength ? title : String(title.prefix(maxLength - 1)) + "…"
    }

    static func statusTitle(
        for clock: ZoneClock,
        at date: Date = .now,
        language: AppLanguage = .english,
        isLast: Bool
    ) -> String {
        let title = menuTitle(
            for: clock,
            at: date,
            language: language,
            maxLength: isLast ? 30 : 28
        )
        return isLast ? title : "\(title)  │"
    }

    static func statusTitle(
        for clocks: [ZoneClock],
        at date: Date = .now,
        language: AppLanguage = .english
    ) -> String {
        guard !clocks.isEmpty else { return "Zonelet" }
        let maxLength = clocks.count == 1 ? 30 : 28
        return clocks
            .map { menuTitle(for: $0, at: date, language: language, maxLength: maxLength) }
            .joined(separator: "  │  ")
    }

    private static func dayMarker(for offset: Int, language: AppLanguage) -> String {
        guard offset != 0 else { return "" }

        return switch (language, offset) {
        case (.simplifiedChinese, -1): " 昨天"
        case (.simplifiedChinese, 1): " 明天"
        case (.simplifiedChinese, let value): " \(value > 0 ? "+" : "")\(value)天"
        case (.english, -1): " Yesterday"
        case (.english, 1): " Tomorrow"
        case (.english, let value): " \(value > 0 ? "+" : "")\(value)d"
        }
    }

    private static func dayComponents(at date: Date, in timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
