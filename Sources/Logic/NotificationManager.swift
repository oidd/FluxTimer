import Foundation
import UserNotifications
import AppKit

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Current authorization status: \(settings.authorizationStatus.rawValue)")
            
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                        DispatchQueue.main.async {
                            if !granted {
                                let alert = NSAlert()
                                alert.messageText = LocalizationManager.shared.t("系统通知权限")
                                alert.informativeText = LocalizationManager.shared.t("权限请求被拒绝或发生错误。请检查系统设置。")
                                alert.addButton(withTitle: "OK")
                                alert.runModal()
                            }
                            completion?(granted)
                        }
                    }
                case .denied:
                    let alert = NSAlert()
                    alert.messageText = LocalizationManager.shared.t("系统通知被禁用")
                    alert.informativeText = LocalizationManager.shared.t("通知权限已被拒绝。请前往“系统设置 > 通知”手动开启 FluxTimer 的权限。")
                    alert.addButton(withTitle: LocalizationManager.shared.t("打开设置"))
                    alert.addButton(withTitle: "OK")
                    
                    if alert.runModal() == .alertFirstButtonReturn {
                        self.openNotificationSettings()
                    }
                    completion?(false)
                case .authorized, .provisional, .ephemeral:
                    completion?(true)
                @unknown default:
                    completion?(false)
                }
            }
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    func sendNotification(title: String, subtitle: String = "") {
        let content = UNMutableNotificationContent()
        content.title = title.isEmpty ? LocalizationManager.shared.t("倒计时结束") : title
        content.subtitle = subtitle
        // content.body = ... (if used)
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
}
