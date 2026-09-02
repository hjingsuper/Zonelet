import Foundation
import Testing
@testable import Zonelet

@Suite("Clock presentation")
struct ClockPresentationTests {
    @Test("Calculates the day difference across zones")
    func dayOffsetAcrossDateLine() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T16:30:00Z"))
        let shanghai = try #require(TimeZone(identifier: "Asia/Shanghai"))
        let losAngeles = try #require(TimeZone(identifier: "America/Los_Angeles"))

        #expect(ClockPresentation.dayOffset(at: date, from: losAngeles, to: shanghai) == 1)
    }

    @Test("Builds a compact menu title")
    func menuTitleIncludesLabelAndTime() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let clock = ZoneClock(timeZoneIdentifier: "UTC", label: "UTC")
        let title = ClockPresentation.menuTitle(for: clock, at: date)

        #expect(title.hasPrefix("UTC "))
        #expect(title.contains("08:05") || title.contains("8:05"))
    }

    @Test("Uses each clock's own display format")
    func perClockDisplayFormat() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T08:05:06Z"))
        let timeOnly = ZoneClock(timeZoneIdentifier: "UTC", label: "UTC", displayFormat: .time24)
        let withSeconds = ZoneClock(timeZoneIdentifier: "UTC", label: "UTC", displayFormat: .timeWithSeconds)

        #expect(ClockPresentation.menuTitle(for: timeOnly, at: date).contains("08:05"))
        #expect(ClockPresentation.menuTitle(for: withSeconds, at: date).contains("08:05:06"))
    }

    @Test("Separates adjacent menu bar clocks")
    func menuBarSeparators() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let clock = ZoneClock(timeZoneIdentifier: "UTC", label: "UTC")

        #expect(ClockPresentation.statusTitle(for: clock, at: date, isLast: false).hasSuffix("  │"))
        #expect(!ClockPresentation.statusTitle(for: clock, at: date, isLast: true).contains("│"))
    }

    @Test("Combines visible clocks into one stable menu bar item")
    func combinedMenuBarTitle() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let lima = ZoneClock(timeZoneIdentifier: "America/Lima", label: "利马")
        let utc = ZoneClock(timeZoneIdentifier: "UTC", label: "UTC")
        let title = ClockPresentation.statusTitle(for: [lima, utc], at: date)

        #expect(title.contains("利马"))
        #expect(title.contains("UTC"))
        #expect(title.components(separatedBy: "│").count == 2)
    }

    @Test("Explains day differences with friendly Chinese words")
    func localizedDayDifference() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T16:30:00Z"))
        let lima = ZoneClock(timeZoneIdentifier: "America/Lima", label: "利马")
        let title = ClockPresentation.menuTitle(
            for: lima,
            at: date,
            language: .simplifiedChinese
        )

        #expect(title.contains("昨天"))
        #expect(!title.contains(" -1"))
    }

    @Test("Formats date and time with a custom pattern")
    func customDateAndTimeFormat() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let value = ClockPresentation.timeString(
            at: date,
            in: .gmt,
            locale: Locale(identifier: "en_US_POSIX"),
            format: "yyyy-MM-dd HH:mm"
        )

        #expect(value == "2026-09-02 08:05")
    }

    @Test("Formats full date and time followed by weekday")
    func fullDateTimeWithWeekdayFormat() throws {
        let date = try #require(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let value = ClockPresentation.timeString(
            at: date,
            in: .gmt,
            locale: Locale(identifier: "zh_CN"),
            format: DisplayFormatPreset.fullDateTimeWithWeekday.pattern
        )

        #expect(DisplayFormatPreset.fullDateTimeWithWeekday.pattern == "yyyy-MM-dd HH:mm EEE")
        #expect(value == "2026-09-02 08:05 周三")
    }

    @MainActor
    @Test("Stores display formats independently")
    func displayFormatPersistence() throws {
        let defaults = try #require(UserDefaults(suiteName: "ZoneletTests.Format.\(UUID())"))
        let languageStore = LanguageStore(defaults: defaults)
        let store = ClockStore(defaults: defaults, languageStore: languageStore)
        store.add(timeZoneIdentifier: "Asia/Shanghai")
        let first = try #require(store.clocks.first)
        let second = try #require(store.clocks.dropFirst().first)

        store.setDisplayFormat(id: first.id, .timeWithSeconds)
        store.setDisplayFormat(id: second.id, .fullDateTime)

        let reloaded = ClockStore(defaults: defaults, languageStore: languageStore)
        #expect(reloaded.clock(id: first.id)?.displayFormatPreset == .timeWithSeconds)
        #expect(reloaded.clock(id: second.id)?.displayFormatPreset == .fullDateTime)
    }

    @MainActor
    @Test("Applies one format to every clock and future clocks")
    func unifiedDisplayFormat() throws {
        let defaults = try #require(UserDefaults(suiteName: "ZoneletTests.UnifiedFormat.\(UUID())"))
        let languageStore = LanguageStore(defaults: defaults)
        let store = ClockStore(defaults: defaults, languageStore: languageStore)

        store.setDisplayFormatForAll(.weekdayTime)
        #expect(store.uniformDisplayFormat == .weekdayTime)
        #expect(store.clocks.allSatisfy { $0.displayFormatPreset == .weekdayTime })

        store.add(timeZoneIdentifier: "Asia/Shanghai")
        #expect(store.clocks.last?.displayFormatPreset == .weekdayTime)

        let first = try #require(store.clocks.first)
        store.setDisplayFormat(id: first.id, .timeWithSeconds)
        #expect(store.uniformDisplayFormat == nil)
    }

    @MainActor
    @Test("Offers beginner-friendly format choices")
    func formatPresetChoices() {
        #expect(DisplayFormatPreset.allCases.count >= 6)
        #expect(Set(DisplayFormatPreset.allCases.map(\.pattern)).count == DisplayFormatPreset.allCases.count)
        #expect(
            DisplayFormatPreset.allCases.allSatisfy {
                !$0.title(language: .simplifiedChinese).isEmpty && !$0.pattern.isEmpty
            }
        )
    }

    @Test("Turns identifiers into friendly city names")
    func catalogProducesFriendlyCityName() {
        #expect(TimeZoneCatalog.cityName(for: "America/New_York") == "New York")
        #expect(
            TimeZoneCatalog.cityName(for: "America/Lima", language: .simplifiedChinese) == "利马"
        )
        #expect(TimeZoneCatalog.cityName(for: "UTC") == "UTC")
    }

    @Test("Finds Pacific time by Chinese and common abbreviations")
    func pacificTimeSearchAliases() throws {
        let pacific = try #require(
            TimeZoneCatalog.candidates(language: .simplifiedChinese)
                .first { $0.id == "America/Los_Angeles" }
        )

        #expect(pacific.matches("太平洋标准时间"))
        #expect(pacific.matches("PST"))
        #expect(pacific.matches("PDT"))
    }

    @MainActor
    @Test("Uses Simplified Chinese by default")
    func simplifiedChineseIsDefault() throws {
        let defaults = try #require(UserDefaults(suiteName: "ZoneletTests.Language.\(UUID())"))
        let languageStore = LanguageStore(defaults: defaults)

        #expect(languageStore.language == .simplifiedChinese)
        #expect(languageStore[.addTimeZone] == "添加地区时间")
    }

    @MainActor
    @Test("Starts with UTC only")
    func utcIsTheOnlyDefaultClock() throws {
        let suite = "ZoneletTests.DefaultClocks.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let languageStore = LanguageStore(defaults: defaults)
        let store = ClockStore(defaults: defaults, languageStore: languageStore)

        #expect(store.clocks.count == 1)
        #expect(store.clocks.first?.timeZoneIdentifier == "UTC")
    }
}
