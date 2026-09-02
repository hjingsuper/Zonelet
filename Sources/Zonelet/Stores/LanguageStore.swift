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
    case automaticUpdatesDescription
    case checkForUpdates
    case chinese
    case disclaimer
    case done
    case displayFormat
    case english
    case hideFromMenuBar
    case label
    case language
    case launchAtLogin
    case launchAtLoginFailed
    case launchAtLoginNeedsApproval
    case retryLaunchAtLogin
    case launchAtLoginUnavailable
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
        case (.simplifiedChinese, .addTimeZone): "添加地区时间"
        case (.simplifiedChinese, .appSubtitle): "地区时间，一眼即知"
        case (.simplifiedChinese, .automaticUpdatesDescription): "自动在后台下载更新，安装完成后重新启动。"
        case (.simplifiedChinese, .checkForUpdates): "检查更新…"
        case (.simplifiedChinese, .chinese): "简体中文"
        case (.simplifiedChinese, .disclaimer): "本软件为免费开源项目，仅供交流学习与个人使用。请遵守相关法律法规与开源协议，勿用于任何商业或非法用途。"
        case (.simplifiedChinese, .done): "完成"
        case (.simplifiedChinese, .displayFormat): "菜单栏格式"
        case (.simplifiedChinese, .english): "English"
        case (.simplifiedChinese, .hideFromMenuBar): "从菜单栏隐藏"
        case (.simplifiedChinese, .label): "名称"
        case (.simplifiedChinese, .language): "语言"
        case (.simplifiedChinese, .launchAtLogin): "开机自启"
        case (.simplifiedChinese, .launchAtLoginFailed): "注册失败，请确认已安装到“应用程序”，然后重新检测。"
        case (.simplifiedChinese, .launchAtLoginNeedsApproval): "需要在“系统设置 → 通用 → 登录项”中允许。"
        case (.simplifiedChinese, .retryLaunchAtLogin): "重新检测"
        case (.simplifiedChinese, .launchAtLoginUnavailable): "未找到登录项，请确认已安装到“应用程序”。"
        case (.simplifiedChinese, .manageClocks): "管理地区时间…"
        case (.simplifiedChinese, .moveDown): "下移"
        case (.simplifiedChinese, .moveUp): "上移"
        case (.simplifiedChinese, .noClocks): "暂无地区时间"
        case (.simplifiedChinese, .noClocksDescription): "添加一个城市或地区即可开始。"
        case (.simplifiedChinese, .openApp): "打开 Zonelet…"
        case (.simplifiedChinese, .quitApp): "退出 Zonelet"
        case (.simplifiedChinese, .remove): "删除"
        case (.simplifiedChinese, .searchPrompt): "搜索城市或地区"
        case (.simplifiedChinese, .showInMenuBar): "在菜单栏显示"
        case (.simplifiedChinese, .visibilityHint): "打开开关，即可让该地区时间常驻菜单栏。"
        case (.simplifiedChinese, .sourceOnGitHub): "在 GitHub 查看源码"
        case (.simplifiedChinese, .uniformFormat): "统一格式"
        case (.simplifiedChinese, .mixedFormats): "多种格式"
        case (.simplifiedChinese, .formatDescription): "这里可统一设置，也可以在每个地区时间右侧单独设置。"

        case (.english, .addTimeZone): "Add Location"
        case (.english, .appSubtitle): "Local times, at a glance"
        case (.english, .automaticUpdatesDescription): "Downloads updates in the background, installs them, then relaunches."
        case (.english, .checkForUpdates): "Check for Updates…"
        case (.english, .chinese): "简体中文"
        case (.english, .disclaimer): "Zonelet is free and open source, intended only for learning, discussion, and personal use. Follow applicable laws and open-source licenses. Do not use it for commercial or illegal purposes."
        case (.english, .done): "Done"
        case (.english, .displayFormat): "Menu Bar Format"
        case (.english, .english): "English"
        case (.english, .hideFromMenuBar): "Hide from Menu Bar"
        case (.english, .label): "Label"
        case (.english, .language): "Language"
        case (.english, .launchAtLogin): "Launch at Login"
        case (.english, .launchAtLoginFailed): "Registration failed. Install Zonelet in Applications, then check again."
        case (.english, .launchAtLoginNeedsApproval): "Allow Zonelet in System Settings → General → Login Items."
        case (.english, .retryLaunchAtLogin): "Check Again"
        case (.english, .launchAtLoginUnavailable): "Login item not found. Make sure Zonelet is installed in Applications."
        case (.english, .manageClocks): "Manage Locations…"
        case (.english, .moveDown): "Move Down"
        case (.english, .moveUp): "Move Up"
        case (.english, .noClocks): "No Locations"
        case (.english, .noClocksDescription): "Add a city or location to get started."
        case (.english, .openApp): "Open Zonelet…"
        case (.english, .quitApp): "Quit Zonelet"
        case (.english, .remove): "Remove"
        case (.english, .searchPrompt): "City or location"
        case (.english, .showInMenuBar): "Show in the menu bar"
        case (.english, .sourceOnGitHub): "View Source on GitHub"
        case (.english, .uniformFormat): "Format All"
        case (.english, .mixedFormats): "Mixed Formats"
        case (.english, .visibilityHint): "Turn a location on to keep its time visible in the menu bar."
        case (.english, .formatDescription): "Set every location here, or choose a different format beside any one."
        }
    }

    private let defaults: UserDefaults
}
