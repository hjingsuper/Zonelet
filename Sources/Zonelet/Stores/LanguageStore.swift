import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
}

enum L10nKey {
    case addTimeZone
    case automaticUpdatesDescription
    case apply
    case cancel
    case checkForUpdates
    case chinese
    case configurationRecovered
    case disclaimer
    case done
    case displayFormat
    case commonTimeFormats
    case commonDateFormats
    case customFormat
    case customizeFormat
    case formatPreview
    case year
    case dateDigits
    case dateSeparator
    case hourCycle
    case digitPadding
    case showSeconds
    case weekday
    case menuBarCharacters
    case menuBarLongHint
    case english
    case language
    case launchAtLogin
    case launchAtLoginFailed
    case launchAtLoginNeedsApproval
    case retryLaunchAtLogin
    case launchAtLoginUnavailable
    case localColumn
    case locationColumn
    case manageClocks
    case menuDisplayColumn
    case noClocks
    case noClocksDescription
    case quitApp
    case remove
    case searchPrompt
    case showInMenuBar
    case sourceOnGitHub
    case timeColumn
    case formatColumn
    case utcColumn
    case uniformFormat
    case updateAvailable
    case dragToReorder
}

@MainActor
@Observable
final class LanguageStore {
    private enum Keys {
        static let appleLanguages = "AppleLanguages"
        static let language = "zonelet.language"
    }

    private(set) var language: AppLanguage
    var onChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = defaults.string(forKey: Keys.language)
            .flatMap(AppLanguage.init(rawValue:)) ?? .simplifiedChinese
        synchronizeBundleLanguage()
    }

    func setLanguage(_ newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        language = newLanguage
        defaults.set(newLanguage.rawValue, forKey: Keys.language)
        synchronizeBundleLanguage()
        onChange?()
    }

    subscript(_ key: L10nKey) -> String {
        switch (language, key) {
        case (.simplifiedChinese, .addTimeZone): "添加地区"
        case (.simplifiedChinese, .automaticUpdatesDescription): "自动在后台下载更新，安装完成后重新启动。"
        case (.simplifiedChinese, .apply): "应用"
        case (.simplifiedChinese, .cancel): "取消"
        case (.simplifiedChinese, .checkForUpdates): "检查更新…"
        case (.simplifiedChinese, .chinese): "简体中文"
        case (.simplifiedChinese, .configurationRecovered): "检测到无效的地区或时间格式，原始配置已备份并安全修复。"
        case (.simplifiedChinese, .disclaimer): "本软件为免费开源项目，仅供交流学习与个人使用。请遵守相关法律法规与开源协议，勿用于任何商业或非法用途。"
        case (.simplifiedChinese, .done): "完成"
        case (.simplifiedChinese, .displayFormat): "时间格式"
        case (.simplifiedChinese, .commonTimeFormats): "仅时间"
        case (.simplifiedChinese, .commonDateFormats): "日期与时间"
        case (.simplifiedChinese, .customFormat): "自定义"
        case (.simplifiedChinese, .customizeFormat): "自定义格式…"
        case (.simplifiedChinese, .formatPreview): "实时预览"
        case (.simplifiedChinese, .year): "年份"
        case (.simplifiedChinese, .dateDigits): "月日"
        case (.simplifiedChinese, .dateSeparator): "日期分隔符"
        case (.simplifiedChinese, .hourCycle): "时间制式"
        case (.simplifiedChinese, .digitPadding): "时间数字"
        case (.simplifiedChinese, .showSeconds): "显示秒钟"
        case (.simplifiedChinese, .weekday): "星期"
        case (.simplifiedChinese, .menuBarCharacters): "菜单栏时间约 %d 个字符"
        case (.simplifiedChinese, .menuBarLongHint): "格式较长，显示多个地区时可能占用较多菜单栏空间。"
        case (.simplifiedChinese, .english): "English"
        case (.simplifiedChinese, .language): "语言"
        case (.simplifiedChinese, .launchAtLogin): "开机自启"
        case (.simplifiedChinese, .launchAtLoginFailed): "注册失败，请确认已安装到“应用程序”，然后重新检测。"
        case (.simplifiedChinese, .launchAtLoginNeedsApproval): "需要在“系统设置 → 通用 → 登录项”中允许。"
        case (.simplifiedChinese, .retryLaunchAtLogin): "重新检测"
        case (.simplifiedChinese, .launchAtLoginUnavailable): "未找到登录项，请确认已安装到“应用程序”。"
        case (.simplifiedChinese, .localColumn): "本机"
        case (.simplifiedChinese, .locationColumn): "地区"
        case (.simplifiedChinese, .manageClocks): "管理地区时间…"
        case (.simplifiedChinese, .menuDisplayColumn): "菜单显示"
        case (.simplifiedChinese, .noClocks): "暂无地区时间"
        case (.simplifiedChinese, .noClocksDescription): "添加一个城市或地区即可开始。"
        case (.simplifiedChinese, .quitApp): "退出 Zonelet"
        case (.simplifiedChinese, .remove): "删除"
        case (.simplifiedChinese, .searchPrompt): "搜索城市或地区"
        case (.simplifiedChinese, .showInMenuBar): "在菜单栏显示"
        case (.simplifiedChinese, .sourceOnGitHub): "在 GitHub 查看源码"
        case (.simplifiedChinese, .timeColumn): "时间"
        case (.simplifiedChinese, .formatColumn): "格式"
        case (.simplifiedChinese, .utcColumn): "UTC"
        case (.simplifiedChinese, .uniformFormat): "统一格式"
        case (.simplifiedChinese, .updateAvailable): "有可用更新…"
        case (.simplifiedChinese, .dragToReorder): "按住拖动以调整顺序"

        case (.english, .addTimeZone): "Add Location"
        case (.english, .automaticUpdatesDescription): "Downloads updates in the background, installs them, then relaunches."
        case (.english, .apply): "Apply"
        case (.english, .cancel): "Cancel"
        case (.english, .checkForUpdates): "Check for Updates…"
        case (.english, .chinese): "简体中文"
        case (.english, .configurationRecovered): "Invalid locations or time formats were found. The original settings were backed up and safely repaired."
        case (.english, .disclaimer): "Zonelet is a free, open-source project for learning and personal use only. Follow applicable laws and open-source licenses; do not use it commercially or illegally."
        case (.english, .done): "Done"
        case (.english, .displayFormat): "Time Format"
        case (.english, .commonTimeFormats): "Time Only"
        case (.english, .commonDateFormats): "Date & Time"
        case (.english, .customFormat): "Custom"
        case (.english, .customizeFormat): "Customize Format…"
        case (.english, .formatPreview): "Live Preview"
        case (.english, .year): "Year"
        case (.english, .dateDigits): "Month & Day"
        case (.english, .dateSeparator): "Date Separator"
        case (.english, .hourCycle): "Hour Cycle"
        case (.english, .digitPadding): "Time Digits"
        case (.english, .showSeconds): "Show Seconds"
        case (.english, .weekday): "Weekday"
        case (.english, .menuBarCharacters): "About %d characters in the menu bar"
        case (.english, .menuBarLongHint): "This format may use substantial menu bar space when several locations are visible."
        case (.english, .english): "English"
        case (.english, .language): "Language"
        case (.english, .launchAtLogin): "Launch at Login"
        case (.english, .launchAtLoginFailed): "Registration failed. Install Zonelet in Applications, then check again."
        case (.english, .launchAtLoginNeedsApproval): "Allow Zonelet in System Settings → General → Login Items."
        case (.english, .retryLaunchAtLogin): "Check Again"
        case (.english, .launchAtLoginUnavailable): "Login item not found. Make sure Zonelet is installed in Applications."
        case (.english, .localColumn): "Local"
        case (.english, .locationColumn): "Location"
        case (.english, .manageClocks): "Manage Locations…"
        case (.english, .menuDisplayColumn): "Menu Bar"
        case (.english, .noClocks): "No Locations"
        case (.english, .noClocksDescription): "Add a city or location to get started."
        case (.english, .quitApp): "Quit Zonelet"
        case (.english, .remove): "Remove"
        case (.english, .searchPrompt): "City or location"
        case (.english, .showInMenuBar): "Show in the menu bar"
        case (.english, .sourceOnGitHub): "View Source on GitHub"
        case (.english, .timeColumn): "Time"
        case (.english, .formatColumn): "Format"
        case (.english, .utcColumn): "UTC"
        case (.english, .uniformFormat): "Format All"
        case (.english, .updateAvailable): "Update Available…"
        case (.english, .dragToReorder): "Hold and drag to reorder"
        }
    }

    private let defaults: UserDefaults

    private func synchronizeBundleLanguage() {
        defaults.set([language.rawValue], forKey: Keys.appleLanguages)
    }
}
