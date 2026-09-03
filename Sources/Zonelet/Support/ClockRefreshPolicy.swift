import Foundation

enum ClockRefreshPolicy {
    static func interval(for clocks: [ZoneClock]) -> TimeInterval {
        clocks.contains { $0.displayFormatPreset == .timeWithSeconds } ? 1 : 60
    }

    static func alignedStart(at date: Date = .now, interval: TimeInterval) -> Date {
        Date(
            timeIntervalSince1970: floor(date.timeIntervalSince1970 / interval) * interval
        )
    }

    static func nextFireDate(after date: Date = .now, interval: TimeInterval) -> Date {
        Date(
            timeIntervalSince1970: (floor(date.timeIntervalSince1970 / interval) + 1) * interval + 0.05
        )
    }
}
