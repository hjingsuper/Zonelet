import SwiftUI

@MainActor
struct AddZoneView: View {
    let store: ClockStore
    let languageStore: LanguageStore

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [TimeZoneCandidate] {
        let existing = Set(store.clocks.map(\.timeZoneIdentifier))
        let available = TimeZoneCatalog.candidates(language: languageStore.language)
            .filter { !existing.contains($0.id) }
        guard !query.isEmpty else { return available }

        return available.filter { $0.matches(query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(languageStore[.addTimeZone])
                    .font(.title2.weight(.semibold))
                Spacer()
                Button(languageStore[.done]) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            TimelineView(.periodic(from: minuteStart, by: 60)) { context in
                List(results) { candidate in
                    Button {
                        store.add(timeZoneIdentifier: candidate.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(candidate.name)
                                    .foregroundStyle(.primary)
                                Text(candidate.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let zone = TimeZone(identifier: candidate.id) {
                                Text(
                                    ClockPresentation.timeString(
                                        at: context.date,
                                        in: zone,
                                        locale: languageStore.language.locale,
                                        format: DisplayFormatPreset.time24.pattern
                                    )
                                )
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
                .searchable(text: $query, placement: .toolbar, prompt: languageStore[.searchPrompt])
            }
        }
        .frame(width: 440, height: 500)
    }

    private var minuteStart: Date {
        ClockRefreshPolicy.alignedStart(interval: 60)
    }
}
