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
                clockTable
            }

            Divider()
            settingsFooter
        }
        .frame(minWidth: 980, idealWidth: 1040, minHeight: 470, idealHeight: 560)
        .background(.regularMaterial)
        .onAppear { launchAtLoginManager.retryRegistration() }
        .sheet(isPresented: $showingAddZone) {
            AddZoneView(store: store, languageStore: languageStore)
        }
    }

    private var clockTable: some View {
        VStack(spacing: 0) {
            tableHeader
            Divider()

            ScrollView {
                TimelineView(
                    .periodic(from: clockRefreshStart, by: clockRefreshInterval)
                ) { context in
                    LazyVStack(spacing: 0) {
                        ForEach(store.clocks) { clock in
                            ClockRowView(
                                clock: clock,
                                date: context.date,
                                store: store,
                                languageStore: languageStore
                            )

                            if clock.id != store.clocks.last?.id {
                                Divider()
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var clockRefreshInterval: TimeInterval {
        ClockRefreshPolicy.interval(for: store.clocks)
    }

    private var clockRefreshStart: Date {
        ClockRefreshPolicy.alignedStart(interval: clockRefreshInterval)
    }

    private var tableHeader: some View {
        HStack(spacing: ClockTableLayout.spacing) {
            Color.clear
                .frame(width: ClockTableLayout.dragHandle, height: 1)

            Text(languageStore[.locationColumn])
                .frame(width: ClockTableLayout.location, alignment: .leading)

            Text(languageStore[.timeColumn])
                .frame(width: ClockTableLayout.time, alignment: .leading)

            Text(languageStore[.localColumn])
                .frame(width: ClockTableLayout.offset, alignment: .leading)

            Text(languageStore[.utcColumn])
                .frame(width: ClockTableLayout.offset, alignment: .leading)

            uniformFormatMenu
                .frame(width: ClockTableLayout.format, alignment: .leading)

            Text(languageStore[.menuDisplayColumn])
                .frame(width: ClockTableLayout.menuVisibility, alignment: .center)

            Color.clear
                .frame(width: ClockTableLayout.actions, height: 1)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }

    private var uniformFormatMenu: some View {
        Menu {
            ForEach(DisplayFormatPreset.allCases) { preset in
                Button {
                    store.setDisplayFormatForAll(preset)
                } label: {
                    if store.uniformDisplayFormat == preset {
                        Label(formatOptionLabel(preset), systemImage: "checkmark")
                    } else {
                        Text(formatOptionLabel(preset))
                    }
                }
            }
        } label: {
            Text(languageStore[.formatColumn])
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help(languageStore[.uniformFormat])
    }

    private func formatOptionLabel(_ preset: DisplayFormatPreset) -> String {
        let preview = ClockPresentation.timeString(
            in: .current,
            locale: languageStore.language.locale,
            format: preset.pattern
        )
        return "\(preset.title(language: languageStore.language)) · \(preview)"
    }

    private var settingsFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.recoveredConfiguration {
                Label(languageStore[.configurationRecovered], systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            HStack(alignment: .center, spacing: 18) {
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
                        HStack(spacing: 8) {
                            Text(statusText)
                                .font(.caption2)
                                .foregroundStyle(.orange)

                            Button(languageStore[.retryLaunchAtLogin]) {
                                launchAtLoginManager.retryRegistration()
                            }
                            .buttonStyle(.link)
                            .font(.caption2)
                        }
                    }
                }

                Spacer(minLength: 16)

                HStack(spacing: 8) {
                    Button(languageStore[.checkForUpdates]) {
                        updateManager.checkForUpdates()
                    }
                    .disabled(!updateManager.isAvailable)

                    Text("v\(appVersion)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(languageStore[.automaticUpdatesDescription])
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

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

    private var appVersion: String {
        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "—"
        guard let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String else { return version }
        return "\(version) (\(build))"
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text("Zonelet")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)

            Spacer()

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
                Label(currentLanguageTitle, systemImage: "character.bubble")
            }
            .controlSize(.regular)
            .fixedSize()
            .help(languageStore[.language])

            if let sourceURL = URL(string: "https://github.com/hjingsuper/Zonelet") {
                Link(destination: sourceURL) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .buttonStyle(.bordered)
                .help(languageStore[.sourceOnGitHub])
            }

            Button {
                showingAddZone = true
            } label: {
                Label(languageStore[.addTimeZone], systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    private var currentLanguageTitle: String {
        switch languageStore.language {
        case .simplifiedChinese:
            languageStore[.chinese]
        case .english:
            languageStore[.english]
        }
    }
}
