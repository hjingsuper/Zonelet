import Foundation

struct TimeZoneCandidate: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
}

enum TimeZoneCatalog {
    static func candidates(language: AppLanguage) -> [TimeZoneCandidate] {
        let identifiers = Set(TimeZone.knownTimeZoneIdentifiers + ["UTC"])

        return identifiers.compactMap { identifier in
            guard let zone = TimeZone(identifier: identifier) else { return nil }
            return TimeZoneCandidate(
                id: identifier,
                name: cityName(for: identifier, language: language),
                detail: "\(identifier)  ·  \(gmtOffset(for: zone))"
            )
        }
        .sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    static func cityName(for identifier: String, language: AppLanguage = .english) -> String {
        if identifier == "UTC" || identifier == "Etc/UTC" || identifier == "GMT" {
            return "UTC"
        }

        if language == .simplifiedChinese, let localized = chineseCityNames[identifier] {
            return localized
        }

        return identifier
            .split(separator: "/")
            .last
            .map(String.init)?
            .replacingOccurrences(of: "_", with: " ") ?? identifier
    }

    private static let chineseCityNames: [String: String] = [
        "America/Lima": "利马",
        "America/Los_Angeles": "洛杉矶",
        "America/New_York": "纽约",
        "America/Toronto": "多伦多",
        "Asia/Hong_Kong": "香港",
        "Asia/Seoul": "首尔",
        "Asia/Shanghai": "上海",
        "Asia/Singapore": "新加坡",
        "Asia/Tokyo": "东京",
        "Australia/Sydney": "悉尼",
        "Europe/Berlin": "柏林",
        "Europe/London": "伦敦",
        "Europe/Paris": "巴黎"
    ]

    static func gmtOffset(for zone: TimeZone, at date: Date = .now) -> String {
        let seconds = zone.secondsFromGMT(for: date)
        if seconds == 0 { return "UTC" }

        let sign = seconds >= 0 ? "+" : "−"
        let totalMinutes = abs(seconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return minutes == 0
            ? "UTC\(sign)\(hours)"
            : String(format: "UTC%@%d:%02d", sign, hours, minutes)
    }
}
