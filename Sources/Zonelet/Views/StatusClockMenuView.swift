import SwiftUI

enum StatusClockMenuLayout {
    static let width: CGFloat = 430
    static let location: CGFloat = 150
    static let time: CGFloat = 120
    static let offset: CGFloat = 50
    static let spacing: CGFloat = 10
}

struct StatusClockMenuHeaderView: View {
    let languageStore: LanguageStore

    var body: some View {
        HStack(spacing: StatusClockMenuLayout.spacing) {
            Text(languageStore[.locationColumn])
                .frame(width: StatusClockMenuLayout.location, alignment: .leading)
            Text(languageStore[.timeColumn])
                .frame(width: StatusClockMenuLayout.time, alignment: .trailing)
            Text(languageStore[.localColumn])
                .frame(width: StatusClockMenuLayout.offset, alignment: .trailing)
            Text(languageStore[.utcColumn])
                .frame(width: StatusClockMenuLayout.offset, alignment: .trailing)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(width: StatusClockMenuLayout.width, height: 24)
    }
}

struct StatusClockMenuRowView: View {
    let clock: ZoneClock
    let date: Date
    let languageStore: LanguageStore
    let showsDivider: Bool

    var body: some View {
        TimelineView(.periodic(from: refreshStart, by: refreshInterval)) { context in
            row(at: context.date)
        }
    }

    private var refreshInterval: TimeInterval {
        ClockRefreshPolicy.interval(for: [clock])
    }

    private var refreshStart: Date {
        ClockRefreshPolicy.alignedStart(at: date, interval: refreshInterval)
    }

    private func row(at currentDate: Date) -> some View {
        HStack(spacing: StatusClockMenuLayout.spacing) {
            Text(
                TimeZoneCatalog.cityName(
                    for: clock.timeZoneIdentifier,
                    language: languageStore.language
                )
            )
            .fontWeight(.medium)
            .lineLimit(1)
            .frame(width: StatusClockMenuLayout.location, alignment: .leading)

            Text(
                ClockPresentation.timeString(
                    at: currentDate,
                    in: clock.timeZone,
                    locale: languageStore.language.locale,
                    format: clock.effectiveDisplayFormat
                )
            )
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: StatusClockMenuLayout.time, alignment: .trailing)

            Text(
                ClockPresentation.relativeOffset(
                    at: currentDate,
                    from: .current,
                    to: clock.timeZone
                )
            )
            .foregroundStyle(.secondary)
            .frame(width: StatusClockMenuLayout.offset, alignment: .trailing)

            Text(ClockPresentation.utcOffset(at: currentDate, in: clock.timeZone))
                .foregroundStyle(.secondary)
                .frame(width: StatusClockMenuLayout.offset, alignment: .trailing)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .frame(width: StatusClockMenuLayout.width, height: 34)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Divider()
                    .padding(.horizontal, 12)
            }
        }
    }
}
