import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
}

enum L10nKey {
    case addTimeZone
    case appSubtitle
    case chinese
    case done
    case displayFormat
    case english
    case hideFromMenuBar
    case label
    case language
    case manageClocks
    case moveDown
    case moveUp
    case noClocks
    case noClocksDescription
    case openApp
    case quitApp
    case remove
    case searchPrompt
    case showInMenuBar
    case sourceOnGitHub
    case uniformFormat
    case mixedFormats
    case visibilityHint
    case formatDescription
}

@MainActor
@Observable
final class LanguageStore {
    private enum Keys {
        static let language = "zonelet.language"
    }

    private(set) var language: AppLanguage
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = defaults.string(forKey: Keys.language)
            .flatMap(AppLanguage.init(rawValue:)) ?? .simplifiedChinese
    }

    func setLanguage(_ newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        language = newLanguage
        defaults.set(newLanguage.rawValue, forKey: Keys.language)
        onChange?()
    }

    subscript(_ key: L10nKey) -> String {
        switch (language, key) {
        case (.simplifiedChinese, .addTimeZone): "添加时区"
        case (.simplifiedChinese, .appSubtitle): "世界时间，一眼即知"
        case (.simplifiedChinese, .chinese): "简体中文"
        case (.simplifiedChinese, .done): "完成"
        case (.simplifiedChinese, .displayFormat): "菜单栏格式"
        case (.simplifiedChinese, .english): "English"
        case (.simplifiedChinese, .hideFromMenuBar): "从菜单栏隐藏"
        case (.simplifiedChinese, .label): "名称"
        case (.simplifiedChinese, .language): "语言"
        case (.simplifiedChinese, .manageClocks): "管理时区…"
        case (.simplifiedChinese, .moveDown): "下移"
        case (.simplifiedChinese, .moveUp): "上移"
        case (.simplifiedChinese, .noClocks): "暂无时区"
        case (.simplifiedChinese, .noClocksDescription): "添加一个城市或时区即可开始。"
        case (.simplifiedChinese, .openApp): "打开 Zonelet…"
        case (.simplifiedChinese, .quitApp): "退出 Zonelet"
        case (.simplifiedChinese, .remove): "删除"
        case (.simplifiedChinese, .searchPrompt): "搜索城市或时区"
        case (.simplifiedChinese, .showInMenuBar): "在菜单栏显示"
        case (.simplifiedChinese, .visibilityHint): "打开开关，即可让该时区常驻菜单栏。"
        case (.simplifiedChinese, .sourceOnGitHub): "在 GitHub 查看源码"
        case (.simplifiedChinese, .uniformFormat): "统一格式"
        case (.simplifiedChinese, .mixedFormats): "多种格式"
        case (.simplifiedChinese, .formatDescription): "这里可统一设置，也可以在每个时区右侧单独设置。"

        case (.english, .addTimeZone): "Add Time Zone"
        case (.english, .appSubtitle): "Your world clocks, at a glance"
        case (.english, .chinese): "简体中文"
        case (.english, .done): "Done"
        case (.english, .displayFormat): "Menu Bar Format"
        case (.english, .english): "English"
        case (.english, .hideFromMenuBar): "Hide from Menu Bar"
        case (.english, .label): "Label"
        case (.english, .language): "Language"
        case (.english, .manageClocks): "Manage Clocks…"
        case (.english, .moveDown): "Move Down"
        case (.english, .moveUp): "Move Up"
        case (.english, .noClocks): "No Clocks"
        case (.english, .noClocksDescription): "Add a city or time zone to get started."
        case (.english, .openApp): "Open Zonelet…"
        case (.english, .quitApp): "Quit Zonelet"
        case (.english, .remove): "Remove"
        case (.english, .searchPrompt): "City or time zone"
        case (.english, .showInMenuBar): "Show in the menu bar"
        case (.english, .sourceOnGitHub): "View Source on GitHub"
        case (.english, .uniformFormat): "Format All"
        case (.english, .mixedFormats): "Mixed Formats"
        case (.english, .visibilityHint): "Turn a clock on to keep it visible in the menu bar."
        case (.english, .formatDescription): "Set every clock here, or choose a different format beside any clock."
        }
    }

    private let defaults: UserDefaults
}
