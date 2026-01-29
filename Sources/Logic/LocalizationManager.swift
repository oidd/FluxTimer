import Foundation

enum AppLanguage: String, CaseIterable {
    case auto = "auto"
    case zh = "zh"
    case en = "en"
    
    var displayName: String {
        switch self {
        case .auto: return LocalizationManager.shared.t("语言：自动")
        case .zh: return "简体中文"
        case .en: return "English"
        }
    }
    
    // Internal display for the picker itself to avoid infinite recursion during init
    var pickerName: String {
        switch self {
        case .auto: return "跟随系统"
        case .zh: return "简体中文"
        case .en: return "English"
        }
    }
}

class LocalizationManager {
    static let shared = LocalizationManager()
    static let languageChangedNotification = Notification.Name("AppLanguageChanged")
    
    func notifyLanguageChange() {
        NotificationCenter.default.post(name: LocalizationManager.languageChangedNotification, object: nil)
    }
    private let translations: [String: [String: String]] = [
        "始终置顶": [
            "zh": "始终置顶",
            "en": "Always on Top"
        ],
        "设置": [
            "zh": "设置",
            "en": "Settings"
        ],
        "退出": [
            "zh": "退出",
            "en": "Quit"
        ],
        "提醒事项...": [
            "zh": "提醒事项...",
            "en": "Reminder..."
        ],
        "预计 %@ 结束计时": [
            "zh": "预计 %@ 结束计时",
            "en": "Estimated end at %@"
        ],
        "自定义": [
            "zh": "自定义",
            "en": "Custom"
        ],
        "倒计时": [
            "zh": "流光倒计时",
            "en": "Flux Timer"
        ],
        "1m 测试": [
            "zh": "1m 测试",
            "en": "1m Test"
        ],
        "休息一下": [
            "zh": "休息一下",
            "en": "Take a Break"
        ],
        "番茄专注": [
            "zh": "番茄专注",
            "en": "Pomodoro"
        ],
        "泡面": [
            "zh": "泡面",
            "en": "Instant Noodles"
        ],
        "时间到": [
            "zh": "时间到",
            "en": "Time's Up"
        ],
        "时间到！": [
            "zh": "时间到！",
            "en": "Time's up!"
        ],
        "倒计时结束": [
            "zh": "倒计时结束",
            "en": "Timer Finished"
        ],
        "常规": [
            "zh": "常规",
            "en": "General"
        ],
        "开机自启动": [
            "zh": "开机自启动",
            "en": "Launch at Login"
        ],
        "通知方式": [
            "zh": "通知方式",
            "en": "Notification Method"
        ],
        "悬浮岛": [
            "zh": "悬浮岛",
            "en": "Floating Island"
        ],
        "系统通知": [
            "zh": "系统通知",
            "en": "System Notification"
        ],
        "打开系统通知设置...": [
            "zh": "打开系统通知设置...",
            "en": "Open Notification Settings..."
        ],
        "请至少保留一种通知方式": [
            "zh": "请至少保留一种通知方式",
            "en": "Please keep at least one notification method"
        ],
        "语言": [
            "zh": "语言 / Language",
            "en": "Language / 语言"
        ],
        "语言：自动": [
            "zh": "自动",
            "en": "Auto"
        ],
        "分钟": [
            "zh": "min",
            "en": "min"
        ],
        "%d min": [
            "zh": "%d min",
            "en": "%d min"
        ],
        "当前语言": [
            "zh": "当前语言",
            "en": "Current Language"
        ],
        "系统通知权限": [
            "zh": "系统通知权限",
            "en": "Notification Permission"
        ],
        "权限请求被拒绝或发生错误。请检查系统设置。": [
            "zh": "权限请求被拒绝或发生错误。请检查系统设置。",
            "en": "Permission denied or an error occurred. Please check System Settings."
        ],
        "系统通知被禁用": [
            "zh": "系统通知被禁用",
            "en": "Notification Disabled"
        ],
        "通知权限已被拒绝。请前往“系统设置 > 通知”手动开启 FluxTimer 的权限。": [
            "zh": "通知权限已被拒绝。请前往“系统设置 > 通知”手动开启 FluxTimer 的权限。",
            "en": "Permission was denied. Please go to 'System Settings > Notifications' and enable permissions for FluxTimer."
        ],
        "延长计时": [
            "zh": "延长计时",
            "en": "Extend Time"
        ],
        "悬浮岛快速延时选项": [
            "zh": "悬浮岛快速延时选项",
            "en": "Quick snooze options"
        ],
        "用于悬浮岛上快捷延长计时时间": [
            "zh": "用于悬浮岛上快捷延长计时时间",
            "en": "Used for quick extension on Floating Island"
        ],
        "提示音效": [
            "zh": "提示音效",
            "en": "Prompt Sound"
        ],
        "超级快捷键": [
            "zh": "超级快捷键",
            "en": "Super Shortcut"
        ],
        "按住快捷键并点按数字，快速创建倒计时": [
            "zh": "按住快捷键并点按数字，快速创建倒计时",
            "en": "Hold keys and type digits to start timer quickly"
        ],
        "按下两个修饰键...": [
            "zh": "按下两个修饰键...",
            "en": "Press 2 modifiers..."
        ],
        "快捷键组合": [
            "zh": "快捷键组合",
            "en": "Shortcut Combo"
        ],
        "需要辅助功能权限": [
            "zh": "需要辅助功能权限",
            "en": "Accessibility Permission Required"
        ],
        "以监听全局快捷键，请在“系统设置 > 隐私与安全性 > 辅助功能”中开启。": [
            "zh": "以监听全局快捷键，请在“系统设置 > 隐私与安全性 > 辅助功能”中开启。",
            "en": "Enable strict privacy access in System Settings > Privacy & Security > Accessibility to listen for global hotkeys."
        ],
        "打开设置": [
            "zh": "打开设置",
            "en": "Open Settings"
        ],
        "最近": [
            "zh": "最近",
            "en": "Recent"
        ],
        "最后一条记录": [
            "zh": "最后一条记录",
            "en": "Last Record"
        ],
        "展现最后一次结束的倒计时记录": [
            "zh": "展现最后一次结束的倒计时记录",
            "en": "Show the last finished timer record."
        ],
        "流光倒计时": [
            "zh": "流光倒计时",
            "en": "Flux Timer"
        ],
        "30秒自动关闭": [
            "zh": "30秒自动关闭",
            "en": "Auto-close in 30s"
        ],
        "保持按住修饰键，输入数字": [
            "zh": "保持按住修饰键，输入数字",
            "en": "Hold modifiers, type digits"
        ],
         "松开修饰键开始计时": [
            "zh": "松开修饰键开始计时",
            "en": "Release to start timer"
        ]
    ]
    
    func t(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "auto"
        let langCode: String
        
        if language == "auto" {
            let systemLang = Locale.preferredLanguages.first ?? "en"
            langCode = systemLang.hasPrefix("zh") ? "zh" : "en"
        } else {
            langCode = language
        }
        
        return translations[key]?[langCode] ?? key
    }
}
