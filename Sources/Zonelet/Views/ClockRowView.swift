import AppKit
import SwiftUI

private enum DragHandleCursor {
    static let move: NSCursor = {
        guard
            let symbol = NSImage(
                systemSymbolName: "arrow.up.and.down.and.arrow.left.and.right",
                accessibilityDescription: nil
            )?.withSymbolConfiguration(
                NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            )
        else {
            return .openHand
        }

        symbol.isTemplate = true
        return NSCursor(
            image: symbol,
            hotSpot: NSPoint(x: symbol.size.width / 2, y: symbol.size.height / 2)
        )
    }()
}

enum ClockTableLayout {
    static let dragHandle: CGFloat = 22
    static let location: CGFloat = 190
    static let time: CGFloat = 220
    static let offset: CGFloat = 64
    static let format: CGFloat = 172
    static let menuVisibility: CGFloat = 88
    static let actions: CGFloat = 24
    static let spacing: CGFloat = 12
}

@MainActor
struct ClockRowView: View {
    let clock: ZoneClock
    let date: Date
    let store: ClockStore
    let languageStore: LanguageStore

    @State private var isDropTargeted = false
    @State private var showingCustomFormatEditor = false

    var body: some View {
        row(at: date)
        .background(isDropTargeted ? Color.accentColor.opacity(0.07) : Color.clear)
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { identifiers, location in
            guard
                let rawIdentifier = identifiers.first,
                let movingID = UUID(uuidString: rawIdentifier)
            else { return false }

            store.move(
                id: movingID,
                relativeTo: clock.id,
                insertAfter: location.y > 35
            )
            return true
        } isTargeted: { isTargeted in
            isDropTargeted = isTargeted
        }
        .animation(.easeOut(duration: 0.12), value: isDropTargeted)
        .sheet(isPresented: $showingCustomFormatEditor) {
            CustomDisplayFormatEditor(
                initialConfiguration: clock.customDisplayFormat
                    ?? CustomDisplayFormat.starting(from: clock.displayFormatPreset),
                languageStore: languageStore,
                previewTimeZone: clock.timeZone
            ) { format in
                store.setCustomDisplayFormat(id: clock.id, format)
            }
        }
    }

    private func row(at date: Date) -> some View {
        HStack(spacing: ClockTableLayout.spacing) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: ClockTableLayout.dragHandle, height: 44)
                .contentShape(Rectangle())
                .draggable(clock.id.uuidString)
                .onHover { isHovering in
                    if isHovering {
                        DragHandleCursor.move.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                .help(languageStore[.dragToReorder])
                .accessibilityLabel(languageStore[.dragToReorder])

            VStack(alignment: .leading, spacing: 3) {
                Text(
                    TimeZoneCatalog.cityName(
                        for: clock.timeZoneIdentifier,
                        language: languageStore.language
                    )
                )
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

                Text(clock.timeZoneIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: ClockTableLayout.location, alignment: .leading)

            Text(
                ClockPresentation.timeString(
                    at: date,
                    in: clock.timeZone,
                    locale: languageStore.language.locale,
                    format: clock.effectiveDisplayFormat
                )
            )
            .font(.title3.monospacedDigit())
            .foregroundStyle(.tint)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .frame(width: ClockTableLayout.time, alignment: .leading)

            Text(
                ClockPresentation.relativeOffset(
                    at: date,
                    from: .current,
                    to: clock.timeZone
                )
            )
            .frame(width: ClockTableLayout.offset, alignment: .leading)

            Text(ClockPresentation.utcOffset(at: date, in: clock.timeZone))
                .frame(width: ClockTableLayout.offset, alignment: .leading)

            formatMenu
                .frame(width: ClockTableLayout.format, alignment: .leading)

            Toggle(
                languageStore[.showInMenuBar],
                isOn: Binding(
                    get: { clock.isVisible },
                    set: { store.setVisible(id: clock.id, $0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            .frame(width: ClockTableLayout.menuVisibility, alignment: .center)

            Menu {
                Button(languageStore[.remove], systemImage: "trash", role: .destructive) {
                    store.remove(id: clock.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .frame(width: ClockTableLayout.actions)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(minHeight: 70)
    }

    private var formatMenu: some View {
        Menu {
            DisplayFormatMenuContent(
                selectedPreset: clock.displayFormatPreset,
                selectedCustomFormat: clock.customDisplayFormat,
                languageStore: languageStore,
                previewTimeZone: clock.timeZone,
                selectPreset: { store.setDisplayFormat(id: clock.id, $0) },
                customize: { showingCustomFormatEditor = true }
            )
        } label: {
            Text(formatTitle)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .controlSize(.small)
        .help(languageStore[.displayFormat])
    }

    private var formatTitle: String {
        clock.displayFormatPreset?.title(language: languageStore.language)
            ?? languageStore[.customFormat]
    }
}
