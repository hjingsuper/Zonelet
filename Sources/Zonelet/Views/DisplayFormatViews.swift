import SwiftUI

@MainActor
struct DisplayFormatMenuContent: View {
    let selectedPreset: DisplayFormatPreset?
    let selectedCustomFormat: CustomDisplayFormat?
    let languageStore: LanguageStore
    let previewTimeZone: TimeZone
    let selectPreset: (DisplayFormatPreset) -> Void
    let customize: () -> Void

    var body: some View {
        Section(languageStore[.commonTimeFormats]) {
            ForEach(DisplayFormatPreset.timeOnly) { preset in
                presetButton(preset)
            }
        }

        Section(languageStore[.commonDateFormats]) {
            ForEach(DisplayFormatPreset.dateAndTime) { preset in
                presetButton(preset)
            }
        }

        Divider()

        Button(action: customize) {
            if selectedCustomFormat != nil {
                Label(customOptionLabel, systemImage: "checkmark")
            } else {
                Label(languageStore[.customizeFormat], systemImage: "slider.horizontal.3")
            }
        }
    }

    @ViewBuilder
    private func presetButton(_ preset: DisplayFormatPreset) -> some View {
        Button {
            selectPreset(preset)
        } label: {
            if selectedPreset == preset {
                Label(optionLabel(preset), systemImage: "checkmark")
            } else {
                Text(optionLabel(preset))
            }
        }
    }

    private func optionLabel(_ preset: DisplayFormatPreset) -> String {
        let preview = ClockPresentation.timeString(
            in: previewTimeZone,
            locale: languageStore.language.locale,
            format: preset.pattern
        )
        return "\(preset.title(language: languageStore.language)) · \(preview)"
    }

    private var customOptionLabel: String {
        guard let selectedCustomFormat else { return languageStore[.customizeFormat] }
        let preview = ClockPresentation.timeString(
            in: previewTimeZone,
            locale: languageStore.language.locale,
            format: selectedCustomFormat.pattern
        )
        return "\(languageStore[.customFormat]) · \(preview)"
    }
}

@MainActor
struct CustomDisplayFormatEditor: View {
    let languageStore: LanguageStore
    let previewTimeZone: TimeZone
    let apply: (CustomDisplayFormat) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var configuration: CustomDisplayFormat

    init(
        initialConfiguration: CustomDisplayFormat,
        languageStore: LanguageStore,
        previewTimeZone: TimeZone,
        apply: @escaping (CustomDisplayFormat) -> Void
    ) {
        self.languageStore = languageStore
        self.previewTimeZone = previewTimeZone
        self.apply = apply
        _configuration = State(initialValue: initialConfiguration)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(languageStore[.customizeFormat])
                    .font(.title2.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)

            previewCard
                .padding(.horizontal, 22)

            Form {
                Picker(languageStore[.year], selection: $configuration.yearStyle) {
                    ForEach(CustomDisplayFormat.YearStyle.allCases) { style in
                        Text(style.title(language: languageStore.language)).tag(style)
                    }
                }

                Picker(languageStore[.dateDigits], selection: $configuration.dateStyle) {
                    ForEach(CustomDisplayFormat.DateStyle.allCases) { style in
                        Text(style.title(language: languageStore.language)).tag(style)
                    }
                }

                Picker(languageStore[.dateSeparator], selection: $configuration.dateSeparator) {
                    ForEach(CustomDisplayFormat.DateSeparator.allCases) { separator in
                        Text(separator.rawValue).tag(separator)
                    }
                }

                Picker(languageStore[.hourCycle], selection: $configuration.hourCycle) {
                    ForEach(CustomDisplayFormat.HourCycle.allCases) { cycle in
                        Text(cycle.title(language: languageStore.language)).tag(cycle)
                    }
                }

                Picker(languageStore[.digitPadding], selection: $configuration.digitStyle) {
                    ForEach(CustomDisplayFormat.DigitStyle.allCases) { style in
                        Text(style.title(language: languageStore.language)).tag(style)
                    }
                }

                Toggle(languageStore[.showSeconds], isOn: $configuration.showsSeconds)

                Picker(languageStore[.weekday], selection: $configuration.weekdayStyle) {
                    ForEach(CustomDisplayFormat.WeekdayStyle.allCases) { style in
                        Text(style.title(language: languageStore.language)).tag(style)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)

            Divider()

            HStack {
                Spacer()
                Button(languageStore[.cancel]) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(languageStore[.apply]) {
                    apply(configuration)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(18)
        }
        .frame(width: 540, height: 550)
    }

    private var previewCard: some View {
        TimelineView(
            .periodic(
                from: ClockRefreshPolicy.alignedStart(interval: configuration.showsSeconds ? 1 : 60),
                by: configuration.showsSeconds ? 1 : 60
            )
        ) { context in
            let preview = ClockPresentation.timeString(
                at: context.date,
                in: previewTimeZone,
                locale: languageStore.language.locale,
                format: configuration.pattern
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(languageStore[.formatPreview])
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(preview)
                    .font(.title2.monospacedDigit().weight(.medium))
                    .foregroundStyle(.tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                HStack(spacing: 6) {
                    Image(systemName: "menubar.rectangle")
                    Text(String(format: languageStore[.menuBarCharacters], preview.count))
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                if preview.count > 20 {
                    Label(languageStore[.menuBarLongHint], systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}
