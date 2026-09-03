import Foundation
import XCTest
@testable import Zonelet

final class ClockPresentationTests: XCTestCase {
    func testCompactTimeZoneOffsets() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-03T09:13:00Z"))
        let shanghai = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        let lima = try XCTUnwrap(TimeZone(identifier: "America/Lima"))
        let kathmandu = try XCTUnwrap(TimeZone(identifier: "Asia/Kathmandu"))

        XCTAssertEqual(ClockPresentation.relativeOffset(at: date, from: shanghai, to: lima), "−13h")
        XCTAssertEqual(ClockPresentation.utcOffset(at: date, in: lima), "−5h")
        XCTAssertEqual(ClockPresentation.utcOffset(at: date, in: kathmandu), "+5h45m")
    }

    func testMenuTitleIncludesLocationAndTime() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let clock = ZoneClock(timeZoneIdentifier: "UTC")
        let title = ClockPresentation.menuTitle(for: clock, at: date)

        XCTAssertTrue(title.hasPrefix("UTC "))
        XCTAssertTrue(title.contains("08:05") || title.contains("8:05"))
    }

    func testPerClockDisplayFormat() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T08:05:06Z"))
        let timeOnly = ZoneClock(timeZoneIdentifier: "UTC", displayFormat: .time24)
        let withSeconds = ZoneClock(timeZoneIdentifier: "UTC", displayFormat: .timeWithSeconds)

        XCTAssertTrue(ClockPresentation.menuTitle(for: timeOnly, at: date).contains("08:05"))
        XCTAssertTrue(ClockPresentation.menuTitle(for: withSeconds, at: date).contains("08:05:06"))
    }

    func testRefreshPolicyUsesAlignedSecondAndMinuteBoundaries() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-03T09:13:27Z"))
        let normal = ZoneClock(timeZoneIdentifier: "UTC")
        let seconds = ZoneClock(
            timeZoneIdentifier: "UTC",
            displayFormat: .timeWithSeconds
        )

        XCTAssertEqual(ClockRefreshPolicy.interval(for: [normal]), 60)
        XCTAssertEqual(ClockRefreshPolicy.interval(for: [normal, seconds]), 1)
        XCTAssertEqual(
            ClockRefreshPolicy.alignedStart(at: date, interval: 60).timeIntervalSince1970,
            floor(date.timeIntervalSince1970 / 60) * 60
        )
        XCTAssertEqual(
            ClockRefreshPolicy.nextFireDate(after: date, interval: 60).timeIntervalSince1970,
            floor(date.timeIntervalSince1970 / 60 + 1) * 60 + 0.05,
            accuracy: 0.001
        )
    }

    func testCombinedMenuBarTitle() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let lima = ZoneClock(timeZoneIdentifier: "America/Lima")
        let utc = ZoneClock(timeZoneIdentifier: "UTC")
        let title = ClockPresentation.statusTitle(
            for: [lima, utc],
            at: date,
            language: .simplifiedChinese
        )

        XCTAssertTrue(title.contains("利马"))
        XCTAssertTrue(title.contains("UTC"))
        XCTAssertEqual(title.components(separatedBy: "|").count, 2)
    }

    func testCombinedMenuBarTitleIsCappedAndSummarizesHiddenClocks() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let clocks = (0..<12).map { index in
            ZoneClock(
                timeZoneIdentifier: index.isMultiple(of: 2) ? "America/Lima" : "Asia/Shanghai",
            )
        }

        let title = ClockPresentation.statusTitle(
            for: clocks,
            at: date,
            language: .simplifiedChinese
        )

        XCTAssertLessThanOrEqual(title.count, 48)
        XCTAssertTrue(title.contains("+"))
    }

    func testMenuTitleOmitsDayMarkers() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T16:30:00Z"))
        let lima = ZoneClock(timeZoneIdentifier: "America/Lima")
        let title = ClockPresentation.menuTitle(for: lima, at: date, language: .simplifiedChinese)

        XCTAssertFalse(title.contains("昨天"))
        XCTAssertFalse(title.contains("明天"))
        XCTAssertFalse(title.contains("-1"))
    }

    func testCustomDateAndTimeFormat() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let value = ClockPresentation.timeString(
            at: date,
            in: .gmt,
            locale: Locale(identifier: "en_US_POSIX"),
            format: "yyyy-MM-dd HH:mm"
        )

        XCTAssertEqual(value, "2026-09-02 08:05")
    }

    func testFullDateTimeWithWeekdayFormat() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-02T08:05:00Z"))
        let value = ClockPresentation.timeString(
            at: date,
            in: .gmt,
            locale: Locale(identifier: "zh_CN"),
            format: DisplayFormatPreset.fullDateTimeWithWeekday.pattern
        )

        XCTAssertEqual(DisplayFormatPreset.fullDateTimeWithWeekday.pattern, "yyyy-MM-dd HH:mm EEE")
        XCTAssertEqual(value, "2026-09-02 08:05 周三")
    }

    @MainActor
    func testDisplayFormatPersistence() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.Format.\(UUID())"))
        let store = ClockStore(defaults: defaults)
        store.add(timeZoneIdentifier: "Asia/Shanghai")
        let first = try XCTUnwrap(store.clocks.first)
        let second = try XCTUnwrap(store.clocks.dropFirst().first)

        store.setDisplayFormat(id: first.id, .timeWithSeconds)
        store.setDisplayFormat(id: second.id, .fullDateTime)

        let reloaded = ClockStore(defaults: defaults)
        XCTAssertEqual(reloaded.clock(id: first.id)?.displayFormatPreset, .timeWithSeconds)
        XCTAssertEqual(reloaded.clock(id: second.id)?.displayFormatPreset, .fullDateTime)
    }

    @MainActor
    func testUnifiedDisplayFormat() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.UnifiedFormat.\(UUID())"))
        let store = ClockStore(defaults: defaults)

        store.setDisplayFormatForAll(.weekdayTime)
        XCTAssertEqual(store.uniformDisplayFormat, .weekdayTime)
        XCTAssertTrue(store.clocks.allSatisfy { $0.displayFormatPreset == .weekdayTime })

        store.add(timeZoneIdentifier: "Asia/Shanghai")
        XCTAssertEqual(store.clocks.last?.displayFormatPreset, .weekdayTime)

        let first = try XCTUnwrap(store.clocks.first)
        store.setDisplayFormat(id: first.id, .timeWithSeconds)
        XCTAssertNil(store.uniformDisplayFormat)
    }

    @MainActor
    func testDragReorderingPersists() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.Reorder.\(UUID())"))
        let store = ClockStore(defaults: defaults)
        store.add(timeZoneIdentifier: "America/Lima")
        store.add(timeZoneIdentifier: "America/Los_Angeles")

        let utc = try XCTUnwrap(store.clocks.first)
        let pacific = try XCTUnwrap(store.clocks.last)
        store.move(id: pacific.id, relativeTo: utc.id, insertAfter: false)

        XCTAssertEqual(store.clocks.first?.id, pacific.id)
        let reloaded = ClockStore(defaults: defaults)
        XCTAssertEqual(reloaded.clocks.first?.id, pacific.id)
    }

    @MainActor
    func testBeginnerFriendlyFormatChoices() {
        XCTAssertGreaterThanOrEqual(DisplayFormatPreset.allCases.count, 6)
        XCTAssertEqual(Set(DisplayFormatPreset.allCases.map(\.pattern)).count, DisplayFormatPreset.allCases.count)
        XCTAssertTrue(
            DisplayFormatPreset.allCases.allSatisfy {
                !$0.title(language: .simplifiedChinese).isEmpty && !$0.pattern.isEmpty
            }
        )
    }

    func testCatalogProducesFriendlyCityName() {
        XCTAssertEqual(TimeZoneCatalog.cityName(for: "America/New_York"), "New York")
        XCTAssertEqual(TimeZoneCatalog.cityName(for: "America/Lima", language: .simplifiedChinese), "利马")
        XCTAssertEqual(
            TimeZoneCatalog.cityName(for: "America/Los_Angeles", language: .simplifiedChinese),
            "太平洋时间"
        )
        XCTAssertEqual(TimeZoneCatalog.cityName(for: "America/Los_Angeles"), "Pacific Time")
        XCTAssertEqual(TimeZoneCatalog.cityName(for: "UTC"), "UTC")
    }

    func testChineseCatalogUsesLocalizedVisibleDetails() throws {
        let cayenne = try XCTUnwrap(
            TimeZoneCatalog.candidates(language: .simplifiedChinese)
                .first { $0.id == "America/Cayenne" }
        )

        XCTAssertFalse(cayenne.name.isEmpty)
        XCTAssertNotEqual(cayenne.name, "Cayenne")
        XCTAssertTrue(cayenne.name.unicodeScalars.contains { !$0.isASCII })
        XCTAssertTrue(cayenne.detail.unicodeScalars.contains { !$0.isASCII })
        XCTAssertTrue(cayenne.detail.contains("UTC−3"))
        XCTAssertFalse(cayenne.detail.contains("America/Cayenne"))
        XCTAssertTrue(cayenne.matches("America/Cayenne"))
    }

    func testPacificTimeSearchAliases() throws {
        let pacific = try XCTUnwrap(
            TimeZoneCatalog.candidates(language: .simplifiedChinese)
                .first { $0.id == "America/Los_Angeles" }
        )

        XCTAssertTrue(pacific.matches("太平洋标准时间"))
        XCTAssertTrue(pacific.matches("PST"))
        XCTAssertTrue(pacific.matches("PDT"))
    }

    func testChineseCatalogDeduplicatesShanghaiAliases() throws {
        let candidates = TimeZoneCatalog.candidates(language: .simplifiedChinese)
        let shanghaiMatches = candidates.filter { $0.matches("上海") }

        XCTAssertEqual(candidates.filter { $0.id == "Asia/Shanghai" }.count, 1)
        XCTAssertFalse(candidates.contains { $0.id == "Asia/Chongqing" })
        XCTAssertFalse(candidates.contains { $0.id == "Asia/Harbin" })
        XCTAssertEqual(shanghaiMatches.count, 1)
        XCTAssertEqual(shanghaiMatches.first?.id, "Asia/Shanghai")
        XCTAssertEqual(shanghaiMatches.first?.name, "上海")
    }

    @MainActor
    func testSimplifiedChineseIsDefault() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.Language.\(UUID())"))
        let languageStore = LanguageStore(defaults: defaults)

        XCTAssertEqual(languageStore.language, .simplifiedChinese)
        XCTAssertEqual(languageStore[.addTimeZone], "添加地区")
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["zh-Hans"])

        languageStore.setLanguage(.english)
        XCTAssertEqual(defaults.stringArray(forKey: "AppleLanguages"), ["en"])
    }

    @MainActor
    func testUTCIsTheOnlyDefaultClock() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.DefaultClocks.\(UUID())"))
        let store = ClockStore(defaults: defaults)

        XCTAssertEqual(store.clocks.count, 1)
        XCTAssertEqual(store.clocks.first?.timeZoneIdentifier, "UTC")
    }

    @MainActor
    func testCorruptConfigurationIsBackedUpBeforeRecovery() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.Corrupt.\(UUID())"))
        let corruptData = Data("not-json".utf8)
        defaults.set(corruptData, forKey: "zonelet.clocks")
        let store = ClockStore(defaults: defaults)

        XCTAssertTrue(store.recoveredConfiguration)
        XCTAssertEqual(store.clocks.map(\.timeZoneIdentifier), ["UTC"])
        XCTAssertEqual(defaults.data(forKey: "zonelet.clocks.corrupt-backup"), corruptData)
        XCTAssertNoThrow(
            try JSONDecoder().decode(
                [ZoneClock].self,
                from: XCTUnwrap(defaults.data(forKey: "zonelet.clocks"))
            )
        )
    }

    @MainActor
    func testInvalidClockDataIsBackedUpAndNormalized() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.InvalidClocks.\(UUID())"))
        let invalidZone = ZoneClock(timeZoneIdentifier: "Invalid/Zone")
        var unknownFormat = ZoneClock(timeZoneIdentifier: "UTC")
        unknownFormat.displayFormatPattern = "unsupported-format"
        let duplicateUTC = ZoneClock(timeZoneIdentifier: "UTC")
        let originalData = try JSONEncoder().encode([
            invalidZone,
            unknownFormat,
            duplicateUTC,
        ])
        defaults.set(originalData, forKey: "zonelet.clocks")

        let store = ClockStore(defaults: defaults)

        XCTAssertTrue(store.recoveredConfiguration)
        XCTAssertEqual(store.clocks.map(\.timeZoneIdentifier), ["UTC"])
        XCTAssertEqual(store.clocks.first?.displayFormatPreset, .time24)
        XCTAssertEqual(defaults.data(forKey: "zonelet.clocks.corrupt-backup"), originalData)

        let countBeforeInvalidAdd = store.clocks.count
        store.add(timeZoneIdentifier: "Invalid/Zone")
        XCTAssertEqual(store.clocks.count, countBeforeInvalidAdd)
    }

    @MainActor
    func testLegacyCustomLabelDoesNotBlockClockMigration() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "ZoneletTests.LegacyLabel.\(UUID())"))
        let encoded = try JSONEncoder().encode([ZoneClock(timeZoneIdentifier: "America/Lima")])
        var legacyClocks = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [[String: Any]]
        )
        legacyClocks[0]["label"] = "Legacy custom name"
        defaults.set(try JSONSerialization.data(withJSONObject: legacyClocks), forKey: "zonelet.clocks")

        let store = ClockStore(defaults: defaults)

        XCTAssertEqual(store.clocks.map(\.timeZoneIdentifier), ["America/Lima"])
        XCTAssertFalse(store.recoveredConfiguration)
        let migratedData = try XCTUnwrap(defaults.data(forKey: "zonelet.clocks"))
        let migratedClocks = try XCTUnwrap(
            JSONSerialization.jsonObject(with: migratedData) as? [[String: Any]]
        )
        XCTAssertNil(migratedClocks.first?["label"])
    }

    @MainActor
    func testTestBundleDoesNotJoinProductionUpdateChannel() {
        XCTAssertFalse(UpdateManager().isAvailable)
    }
}
