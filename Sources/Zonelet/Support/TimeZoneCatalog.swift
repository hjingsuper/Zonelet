import Foundation

struct TimeZoneCandidate: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let searchTerms: [String]

    func matches(_ query: String) -> Bool {
        name.localizedCaseInsensitiveContains(query) ||
            id.localizedCaseInsensitiveContains(query) ||
            detail.localizedCaseInsensitiveContains(query) ||
            searchTerms.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

enum TimeZoneCatalog {
    static func candidates(language: AppLanguage) -> [TimeZoneCandidate] {
        localizedEntries(for: language).compactMap { entry in
            guard let zone = TimeZone(identifier: entry.id) else { return nil }
            return TimeZoneCandidate(
                id: entry.id,
                name: entry.name,
                detail: candidateDetail(
                    for: entry.id,
                    zone: zone,
                    language: language,
                    localizedZoneName: entry.localizedZoneName
                ),
                searchTerms: entry.searchTerms
            )
        }
    }

    static func cityName(for identifier: String, language: AppLanguage = .english) -> String {
        if identifier == "UTC" || identifier == "Etc/UTC" || identifier == "GMT" {
            return "UTC"
        }

        if language == .simplifiedChinese, let localized = chineseCityNames[identifier] {
            return localized
        }

        if language == .english, let localized = englishCityNames[identifier] {
            return localized
        }

        if let localized = systemCityNames(for: language)[identifier] {
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
        "America/Los_Angeles": "太平洋时间",
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

    private static let englishCityNames: [String: String] = [
        "America/Los_Angeles": "Pacific Time"
    ]

    private static let chineseSystemCityNames = makeSystemCityNames(
        locale: AppLanguage.simplifiedChinese.locale
    )

    private static let englishSystemCityNames = makeSystemCityNames(
        locale: AppLanguage.english.locale
    )

    private struct LocalizedEntry {
        let id: String
        let name: String
        let localizedZoneName: String?
        let searchTerms: [String]
    }

    private static let chineseEntries = makeLocalizedEntries(language: .simplifiedChinese)
    private static let englishEntries = makeLocalizedEntries(language: .english)

    private static let searchAliases: [String: [String]] = [
        "America/Los_Angeles": [
            "太平洋时间",
            "太平洋标准时间",
            "太平洋夏令时间",
            "Pacific Time",
            "Pacific Standard Time",
            "Pacific Daylight Time",
            "PST",
            "PDT"
        ]
    ]

    /// `TimeZone.knownTimeZoneIdentifiers` also contains compatibility links
    /// such as Asia/Chongqing and Asia/Harbin. `zone.tab` is the system
    /// database's canonical geographic list, so using it avoids presenting
    /// several historical aliases as identical locations.
    private static let canonicalTimeZoneIdentifiers: Set<String> = {
        let knownIdentifiers = Set(TimeZone.knownTimeZoneIdentifiers)
        guard let contents = try? String(
            contentsOfFile: "/usr/share/zoneinfo/zone.tab",
            encoding: .utf8
        ) else {
            return knownIdentifiers
                .subtracting(["Asia/Chongqing", "Asia/Harbin"])
                .union(["UTC"])
        }

        let identifiers = contents
            .split(whereSeparator: \.isNewline)
            .compactMap { line -> String? in
                guard !line.hasPrefix("#") else { return nil }
                let columns = line.split(separator: "\t", omittingEmptySubsequences: false)
                guard columns.count >= 3 else { return nil }
                let identifier = String(columns[2])
                return knownIdentifiers.contains(identifier) ? identifier : nil
            }
        return Set(identifiers).union(["UTC"])
    }()

    private static func systemCityNames(for language: AppLanguage) -> [String: String] {
        switch language {
        case .simplifiedChinese:
            chineseSystemCityNames
        case .english:
            englishSystemCityNames
        }
    }

    private static func localizedEntries(for language: AppLanguage) -> [LocalizedEntry] {
        switch language {
        case .simplifiedChinese:
            chineseEntries
        case .english:
            englishEntries
        }
    }

    private static func makeLocalizedEntries(language: AppLanguage) -> [LocalizedEntry] {
        canonicalTimeZoneIdentifiers.compactMap { identifier in
            guard let zone = TimeZone(identifier: identifier) else { return nil }
            return LocalizedEntry(
                id: identifier,
                name: cityName(for: identifier, language: language),
                localizedZoneName: language == .simplifiedChinese
                    ? zone.localizedName(for: .generic, locale: language.locale)
                    : nil,
                searchTerms: searchAliases[identifier] ?? []
            )
        }
        .sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func makeSystemCityNames(locale: Locale) -> [String: String] {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "VVV"
        let referenceDate = Date(timeIntervalSince1970: 0)

        return TimeZone.knownTimeZoneIdentifiers.reduce(into: [:]) { result, identifier in
            guard let zone = TimeZone(identifier: identifier) else { return }
            formatter.timeZone = zone
            let name = formatter.string(from: referenceDate)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name != identifier else { return }
            result[identifier] = name
        }
    }

    private static func candidateDetail(
        for identifier: String,
        zone: TimeZone,
        language: AppLanguage,
        localizedZoneName: String?
    ) -> String {
        let offset = gmtOffset(for: zone)
        guard language == .simplifiedChinese else {
            return "\(identifier)  ·  \(offset)"
        }
        guard identifier != "UTC", identifier != "Etc/UTC", identifier != "GMT" else {
            return "UTC"
        }

        let detailName = localizedZoneName
            ?? "\(cityName(for: identifier, language: language))时间"
        return "\(detailName)  ·  \(offset)"
    }

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
