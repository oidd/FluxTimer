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
        case .auto: return "自动 / Auto"
        case .zh: return "简体中文"
        case .en: return "English"
        }
    }
}

class LocalizationManager {
    static let shared = LocalizationManager()
    
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
            "zh": "倒计时",
            "en": "Timer"
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
        "通用": [
            "zh": "通用",
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
        "悬浮岛 (灵动岛样式)": [
            "zh": "悬浮岛 (灵动岛样式)",
            "en": "Floating Island (Island Style)"
        ],
        "系统通知 (通知中心)": [
            "zh": "系统通知 (通知中心)",
            "en": "System Notification (Native)"
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
            "zh": "语言",
            "en": "Language"
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
