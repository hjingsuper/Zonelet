import Foundation

enum DisplayFormatPreset: String, CaseIterable, Identifiable {
    case time24
    case timeWithSeconds
    case time12
    case monthDayTime
    case localizedDateTime
    case weekdayTime
    case fullDateTime
    case fullDateTimeWithWeekday
    case iso8601

    var id: String { rawValue }

    var pattern: String {
        switch self {
        case .time24: "HH:mm"
        case .timeWithSeconds: "HH:mm:ss"
        case .time12: "h:mm a"
        case .monthDayTime: "MM-dd HH:mm"
        case .localizedDateTime: "MMM d HH:mm"
        case .weekdayTime: "EEE HH:mm"
        case .fullDateTime: "yyyy-MM-dd HH:mm"
        case .fullDateTimeWithWeekday: "yyyy-MM-dd HH:mm EEE"
        case .iso8601: "yyyy-MM-dd'T'HH:mm"
        }
    }

    func title(language: AppLanguage) -> String {
        switch (language, self) {
        case (.simplifiedChinese, .time24): "24 小时"
        case (.simplifiedChinese, .timeWithSeconds): "带秒"
        case (.simplifiedChinese, .time12): "12 小时"
        case (.simplifiedChinese, .monthDayTime): "月日 + 时间"
        case (.simplifiedChinese, .localizedDateTime): "本地日期 + 时间"
        case (.simplifiedChinese, .weekdayTime): "星期 + 时间"
        case (.simplifiedChinese, .fullDateTime): "完整日期 + 时间"
        case (.simplifiedChinese, .fullDateTimeWithWeekday): "日期时间 + 星期"
        case (.simplifiedChinese, .iso8601): "ISO 日期 + 时间"

        case (.english, .time24): "24-hour"
        case (.english, .timeWithSeconds): "With Seconds"
        case (.english, .time12): "12-hour"
        case (.english, .monthDayTime): "Month/Day + Time"
        case (.english, .localizedDateTime): "Local Date + Time"
        case (.english, .weekdayTime): "Weekday + Time"
        case (.english, .fullDateTime): "Full Date + Time"
        case (.english, .fullDateTimeWithWeekday): "Date, Time + Weekday"
        case (.english, .iso8601): "ISO Date + Time"
        }
    }
}
