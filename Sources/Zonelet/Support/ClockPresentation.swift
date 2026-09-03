import Foundation

enum ClockPresentation {
    private struct FormatterKey: Hashable {
        let localeIdentifier: String
        let timeZoneIdentifier: String
        let format: String?
    }

    private static let formatterLock = NSLock()
    private static var formatters: [FormatterKey: DateFormatter] = [:]

    static func timeString(
        at date: Date = .now,
        in timeZone: TimeZone,
        locale: Locale = .current,
        format: String? = nil
    ) -> String {
        let key = FormatterKey(
            localeIdentifier: locale.identifier,
            timeZoneIdentifier: timeZone.identifier,
            format: format
        )

        formatterLock.lock()
        defer { formatterLock.unlock() }

        let formatter: DateFormatter
        if let cached = formatters[key] {
            formatter = cached
        } else {
            if formatters.count >= 256 {
                formatters.removeAll(keepingCapacity: true)
            }
            let created = DateFormatter()
            created.locale = locale
            created.timeZone = timeZone
            if let format {
                created.dateFormat = format
            } else {
                created.dateStyle = .none
                created.timeStyle = .short
            }
            formatters[key] = created
            formatter = created
        }
        return formatter.string(from: date)
    }

    static func relativeOffset(
        at date: Date = .now,
        from referenceTimeZone: TimeZone,
        to targetTimeZone: TimeZone
    ) -> String {
        let difference = targetTimeZone.secondsFromGMT(for: date)
            - referenceTimeZone.secondsFromGMT(for: date)
        return compactOffset(seconds: difference)
    }

    static func utcOffset(
        at date: Date = .now,
        in timeZone: TimeZone
    ) -> String {
        compactOffset(seconds: timeZone.secondsFromGMT(for: date))
    }

    static func menuTitle(
        for clock: ZoneClock,
        at date: Date = .now,
        language: AppLanguage = .english,
        maxLength: Int = 30
    ) -> String {
        let time = timeString(
            at: date,
            in: clock.timeZone,
            locale: language.locale,
            format: clock.effectiveDisplayFormat
        )
        let name = TimeZoneCatalog.cityName(
            for: clock.timeZoneIdentifier,
            language: language
        )
        let title = "\(name) \(time)"
        return title.count <= maxLength ? title : String(title.prefix(maxLength - 1)) + "…"
    }

    static func statusTitle(
        for clocks: [ZoneClock],
        at date: Date = .now,
        language: AppLanguage = .english,
        maxLength: Int = 48
    ) -> String {
        guard !clocks.isEmpty else { return "Zonelet" }

        var components: [String] = []
        for (index, clock) in clocks.enumerated() {
            let component = menuTitle(
                for: clock,
                at: date,
                language: language,
                maxLength: clocks.count == 1 ? min(30, maxLength) : 28
            )
            let hiddenAfterCandidate = clocks.count - index - 1
            let proposed = (components + [component]).joined(separator: " | ")
            let reservedSuffix = hiddenAfterCandidate > 0
                ? " | +\(hiddenAfterCandidate)"
                : ""

            if proposed.count + reservedSuffix.count <= maxLength {
                components.append(component)
                continue
            }

            let hiddenCount = clocks.count - index
            if components.isEmpty {
                let suffix = hiddenCount > 1 ? " | +\(hiddenCount - 1)" : ""
                components.append(
                    truncated(component, maxLength: max(1, maxLength - suffix.count))
                )
                if hiddenCount > 1 {
                    components.append("+\(hiddenCount - 1)")
                }
            } else {
                components.append("+\(hiddenCount)")
            }
            break
        }

        return components.joined(separator: " | ")
    }

    private static func compactOffset(seconds: Int) -> String {
        guard seconds != 0 else { return "±0" }

        let sign = seconds > 0 ? "+" : "−"
        let totalMinutes = abs(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if minutes == 0 { return "\(sign)\(hours)h" }
        if hours == 0 { return "\(sign)\(minutes)m" }
        return "\(sign)\(hours)h\(minutes)m"
    }

    private static func truncated(_ value: String, maxLength: Int) -> String {
        guard value.count > maxLength else { return value }
        guard maxLength > 1 else { return "…" }
        return String(value.prefix(maxLength - 1)) + "…"
    }
}
