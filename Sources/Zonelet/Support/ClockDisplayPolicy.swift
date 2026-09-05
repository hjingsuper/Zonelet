import Foundation

enum ClockDisplayPolicy {
    static func menuBarClocks(from clocks: [ZoneClock]) -> [ZoneClock] {
        clocks.filter(\.isVisible)
    }

    static func popupClocks(from clocks: [ZoneClock]) -> [ZoneClock] {
        clocks
    }
}
