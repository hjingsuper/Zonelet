import Foundation

struct CustomDisplayFormat: Codable, Equatable {
    enum YearStyle: String, Codable, CaseIterable, Identifiable {
        case hidden
        case short
        case full

        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            switch (language, self) {
            case (.simplifiedChinese, .hidden): "不显示"
            case (.simplifiedChinese, .short): "26"
            case (.simplifiedChinese, .full): "2026"
            case (.english, .hidden): "Hidden"
            case (.english, .short): "26"
            case (.english, .full): "2026"
            }
        }
    }

    enum DateStyle: String, Codable, CaseIterable, Identifiable {
        case hidden
        case compact
        case padded

        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            switch (language, self) {
            case (.simplifiedChinese, .hidden): "不显示"
            case (.simplifiedChinese, .compact): "9-5"
            case (.simplifiedChinese, .padded): "09-05"
            case (.english, .hidden): "Hidden"
            case (.english, .compact): "9-5"
            case (.english, .padded): "09-05"
            }
        }
    }

    enum DateSeparator: String, Codable, CaseIterable, Identifiable {
        case hyphen = "-"
        case slash = "/"
        case dot = "."

        var id: String { rawValue }
    }

    enum HourCycle: String, Codable, CaseIterable, Identifiable {
        case twentyFour
        case twelve

        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            switch (language, self) {
            case (.simplifiedChinese, .twentyFour): "24 小时"
            case (.simplifiedChinese, .twelve): "12 小时"
            case (.english, .twentyFour): "24-hour"
            case (.english, .twelve): "12-hour"
            }
        }
    }

    enum DigitStyle: String, Codable, CaseIterable, Identifiable {
        case compact
        case padded

        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            switch (language, self) {
            case (.simplifiedChinese, .compact): "不补零（5:3）"
            case (.simplifiedChinese, .padded): "补零（05:03）"
            case (.english, .compact): "No zeros (5:3)"
            case (.english, .padded): "Padded (05:03)"
            }
        }
    }

    enum WeekdayStyle: String, Codable, CaseIterable, Identifiable {
        case hidden
        case narrow
        case short
        case full

        var id: String { rawValue }

        func title(language: AppLanguage) -> String {
            switch (language, self) {
            case (.simplifiedChinese, .hidden): "不显示"
            case (.simplifiedChinese, .narrow): "一"
            case (.simplifiedChinese, .short): "周一"
            case (.simplifiedChinese, .full): "星期一"
            case (.english, .hidden): "Hidden"
            case (.english, .narrow): "M"
            case (.english, .short): "Mon"
            case (.english, .full): "Monday"
            }
        }
    }

    var yearStyle: YearStyle
    var dateStyle: DateStyle
    var dateSeparator: DateSeparator
    var hourCycle: HourCycle
    var digitStyle: DigitStyle
    var showsSeconds: Bool
    var weekdayStyle: WeekdayStyle

    static let compactShort = CustomDisplayFormat(
        yearStyle: .short,
        dateStyle: .compact,
        dateSeparator: .hyphen,
        hourCycle: .twentyFour,
        digitStyle: .compact,
        showsSeconds: false,
        weekdayStyle: .narrow
    )

    var pattern: String {
        var components: [String] = []
        var dateParts: [String] = []

        switch yearStyle {
        case .hidden: break
        case .short: dateParts.append("yy")
        case .full: dateParts.append("yyyy")
        }
        switch dateStyle {
        case .hidden: break
        case .compact: dateParts.append(contentsOf: ["M", "d"])
        case .padded: dateParts.append(contentsOf: ["MM", "dd"])
        }
        if !dateParts.isEmpty {
            components.append(dateParts.joined(separator: dateSeparator.rawValue))
        }

        let hour: String
        switch (hourCycle, digitStyle) {
        case (.twentyFour, .compact): hour = "H"
        case (.twentyFour, .padded): hour = "HH"
        case (.twelve, .compact): hour = "h"
        case (.twelve, .padded): hour = "hh"
        }
        let minute = digitStyle == .compact ? "m" : "mm"
        let second = digitStyle == .compact ? "s" : "ss"
        var time = "\(hour):\(minute)"
        if showsSeconds {
            time += ":\(second)"
        }
        if hourCycle == .twelve {
            time += " a"
        }
        components.append(time)

        switch weekdayStyle {
        case .hidden: break
        case .narrow: components.append("EEEEE")
        case .short: components.append("EEE")
        case .full: components.append("EEEE")
        }

        return components.joined(separator: " ")
    }

    static func starting(from preset: DisplayFormatPreset?) -> CustomDisplayFormat {
        guard let preset else { return .compactShort }
        switch preset {
        case .time24:
            return .init(
                yearStyle: .hidden,
                dateStyle: .hidden,
                dateSeparator: .hyphen,
                hourCycle: .twentyFour,
                digitStyle: .padded,
                showsSeconds: false,
                weekdayStyle: .hidden
            )
        case .timeWithSeconds:
            var value = starting(from: .time24)
            value.showsSeconds = true
            return value
        case .time12:
            var value = starting(from: .time24)
            value.hourCycle = .twelve
            return value
        case .monthDayTime, .localizedDateTime:
            var value = starting(from: .time24)
            value.dateStyle = .padded
            return value
        case .weekdayTime:
            var value = starting(from: .time24)
            value.weekdayStyle = .short
            return value
        case .compactShortDateTime:
            return .compactShort
        case .fullDateTime, .iso8601:
            var value = starting(from: .time24)
            value.yearStyle = .full
            value.dateStyle = .padded
            return value
        case .fullDateTimeWithWeekday:
            var value = starting(from: .fullDateTime)
            value.weekdayStyle = .short
            return value
        }
    }
}
