import SwiftUI

@MainActor
struct ClockRowView: View {
    let clock: ZoneClock
    let index: Int
    let count: Int
    let store: ClockStore
    let languageStore: LanguageStore

    @State private var draftLabel = ""

    var body: some View {
        HStack(spacing: 12) {
            Toggle(
                "\(languageStore[.showInMenuBar]): \(clock.label)",
                isOn: Binding(
                    get: { clock.isVisible },
                    set: { store.setVisible(id: clock.id, $0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)

            VStack(alignment: .leading, spacing: 3) {
                TextField(languageStore[.label], text: $draftLabel)
                    .textFieldStyle(.plain)
                    .font(.headline)
                    .onChange(of: draftLabel) { _, newValue in
                        guard newValue != clock.label else { return }
                        store.rename(id: clock.id, to: newValue)
                    }
                    .onChange(of: clock.label) { _, newValue in draftLabel = newValue }

                Text("\(clock.timeZoneIdentifier) · \(TimeZoneCatalog.gmtOffset(for: clock.timeZone))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(
                    ClockPresentation.timeString(
                        in: clock.timeZone,
                        format: clock.effectiveDisplayFormat
                    )
                )
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(.secondary)

                Menu {
                    ForEach(DisplayFormatPreset.allCases) { preset in
                        Button(formatOptionLabel(preset)) {
                            store.setDisplayFormat(id: clock.id, preset)
                        }
                    }
                } label: {
                    Text(clock.displayFormatPreset.title(language: languageStore.language))
                        .frame(minWidth: 115, alignment: .trailing)
                }
                .menuStyle(.borderlessButton)
                .controlSize(.small)
                .help(languageStore[.displayFormat])
            }

            Menu {
                Button(languageStore[.moveUp], systemImage: "arrow.up") { store.moveUp(id: clock.id) }
                    .disabled(index == 0)
                Button(languageStore[.moveDown], systemImage: "arrow.down") { store.moveDown(id: clock.id) }
                    .disabled(index == count - 1)
                Divider()
                Button(languageStore[.remove], systemImage: "trash", role: .destructive) {
                    store.remove(id: clock.id)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.vertical, 7)
        .onAppear { draftLabel = clock.label }
    }

    private func formatOptionLabel(_ preset: DisplayFormatPreset) -> String {
        let preview = ClockPresentation.timeString(
            in: clock.timeZone,
            format: preset.pattern
        )
        return "\(preset.title(language: languageStore.language)) · \(preview)"
    }
}
