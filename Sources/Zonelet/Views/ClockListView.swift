import SwiftUI

@MainActor
struct ClockListView: View {
    let store: ClockStore
    let languageStore: LanguageStore
    let launchAtLoginManager: LaunchAtLoginManager
    let updateManager: UpdateManager

    @State private var showingAddZone = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if store.clocks.isEmpty {
                ContentUnavailableView {
                    Label(languageStore[.noClocks], systemImage: "clock")
                } description: {
                    Text(languageStore[.noClocksDescription])
                } actions: {
                    Button(languageStore[.addTimeZone]) { showingAddZone = true }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(store.clocks.enumerated()), id: \.element.id) { index, clock in
                        ClockRowView(
                            clock: clock,
                            index: index,
                            count: store.clocks.count,
                            store: store,
                            languageStore: languageStore
                        )
                    }
                }
                .listStyle(.inset)
            }

            Divider()
            settingsFooter
        }
        .frame(minWidth: 560, idealWidth: 620, minHeight: 460, idealHeight: 560)
        .background(.regularMaterial)
        .onAppear { launchAtLoginManager.refresh() }
        .sheet(isPresented: $showingAddZone) {
            AddZoneView(
                store: store,
                languageStore: languageStore
            )
        }
    }

    private func formatOptionLabel(_ preset: DisplayFormatPreset) -> String {
        let preview = ClockPresentation.timeString(in: .current, format: preset.pattern)
        return "\(preset.title(language: languageStore.language)) · \(preview)"
    }

    private var settingsFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "calendar.badge.clock")
                Text(languageStore[.uniformFormat])
                    .foregroundStyle(.primary)
                Spacer()
                Menu {
                    ForEach(DisplayFormatPreset.allCases) { preset in
                        Button(formatOptionLabel(preset)) {
                            store.setDisplayFormatForAll(preset)
                        }
                    }
                } label: {
                    Text(
                        store.uniformDisplayFormat?.title(language: languageStore.language)
                            ?? languageStore[.mixedFormats]
                    )
                    .frame(minWidth: 110, alignment: .trailing)
                }
                .menuStyle(.borderlessButton)
            }

            Text(languageStore[.formatDescription])
                .font(.caption2)
                .padding(.leading, 23)

            Divider()

            HStack(alignment: .top, spacing: 22) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(
                        languageStore[.launchAtLogin],
                        isOn: Binding(
                            get: { launchAtLoginManager.isEnabled },
                            set: { launchAtLoginManager.setEnabled($0) }
                        )
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)

                    if let statusText = launchAtLoginStatusText {
                        Text(statusText)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Button(languageStore[.checkForUpdates]) {
                        updateManager.checkForUpdates()
                    }
                    Text(languageStore[.automaticUpdatesDescription])
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Label {
                Text(languageStore[.disclaimer])
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.tint)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var launchAtLoginStatusText: String? {
        switch launchAtLoginManager.status {
        case .disabled, .enabled:
            nil
        case .requiresApproval:
            languageStore[.launchAtLoginNeedsApproval]
        case .unavailable:
            languageStore[.launchAtLoginUnavailable]
        case .failed:
            languageStore[.launchAtLoginFailed]
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe.americas.fill")
                .font(.title2)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text("Zonelet")
                    .font(.title2.weight(.semibold))
                Text(languageStore[.appSubtitle])
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link(destination: URL(string: "https://github.com/hjingsuper/Zonelet")!) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            }
            .help(languageStore[.sourceOnGitHub])

            Menu {
                Button {
                    languageStore.setLanguage(.simplifiedChinese)
                } label: {
                    if languageStore.language == .simplifiedChinese {
                        Label(languageStore[.chinese], systemImage: "checkmark")
                    } else {
                        Text(languageStore[.chinese])
                    }
                }
                Button {
                    languageStore.setLanguage(.english)
                } label: {
                    if languageStore.language == .english {
                        Label(languageStore[.english], systemImage: "checkmark")
                    } else {
                        Text(languageStore[.english])
                    }
                }
            } label: {
                Image(systemName: "character.bubble")
            }
            .menuStyle(.borderlessButton)
            .help(languageStore[.language])

            Button {
                showingAddZone = true
            } label: {
                Label(languageStore[.addTimeZone], systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(18)
    }
}
