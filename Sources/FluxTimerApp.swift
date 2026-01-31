import SwiftUI
import AppKit

@main
struct FluxTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Only provide Settings scene, which doesn't show a window on launch
        Settings {
            EmptyView()
        }
    }
}

class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingPanel: FloatingPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Managers
        _ = NotificationManager.shared
        _ = SuperKeyManager.shared
        
        // Setup initial menu bar after a short delay to ensure SwiftUI doesn't override it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupMenuBar()
        }
        
        // Observe language changes
        NotificationCenter.default.addObserver(self, selector: #selector(languageChanged), name: LocalizationManager.languageChangedNotification, object: nil)
        
        // Observe dock icon toggle
        NotificationCenter.default.addObserver(self, selector: #selector(toggleDockIcon), name: NSNotification.Name("ToggleDockIcon"), object: nil)
        
        // Ensure the app activation policy is correctly set on launch
        let showIcon = UserDefaults.standard.bool(forKey: "showDockIcon")
        NSApp.setActivationPolicy(showIcon ? .regular : .accessory)
        
        // Request notification permission if enabled in AppStorage
        if UserDefaults.standard.bool(forKey: "useSystemNotification") {
            NotificationManager.shared.requestAuthorization()
        }
        
        // Create the floating panel
        let contentView = ContentView()
        
        floatingPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600), // Expanded for Drag buffer
            backing: .buffered,
            defer: false
        )
        
        floatingPanel?.contentView = ClickThroughHostingView(rootView: contentView.preferredColorScheme(.dark))
        floatingPanel?.appearance = NSAppearance(named: .vibrantDark)
        floatingPanel?.center() // Center on screen initially
        floatingPanel?.makeKeyAndOrderFront(nil)
    }

    @objc private func languageChanged() {
        setupMenuBar()
    }

    private func setupMenuBar() {
        let l10n = LocalizationManager.shared
        let appName = l10n.t("流光倒计时")
        
        let mainMenu = NSMenu()
        
        // 1. App Menu
        let appMenu = NSMenu()
        
        let aboutItem = NSMenuItem(title: String(format: l10n.t("关于 %@"), appName), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(aboutItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let settingsItem = NSMenuItem(title: l10n.t("设置"), action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(settingsItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let servicesItem = NSMenuItem(title: l10n.t("服务"), action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu()
        NSApp.servicesMenu = servicesMenu
        servicesItem.submenu = servicesMenu
        appMenu.addItem(servicesItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let hideItem = NSMenuItem(title: String(format: l10n.t("隐藏 %@"), appName), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(hideItem)
        
        let hideOthersItem = NSMenuItem(title: l10n.t("隐藏其他"), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        
        let showAllItem = NSMenuItem(title: l10n.t("显示全部"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(showAllItem)
        
        appMenu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: l10n.t("退出"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenu.addItem(quitItem)
        
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        NSApp.mainMenu = mainMenu
    }

    @objc private func toggleDockIcon(_ notification: Notification) {
        if let show = notification.userInfo?["show"] as? Bool {
            NSApp.setActivationPolicy(show ? .regular : .accessory)
            
            // After policy change, the app might lose focus or windows might be re-ordered.
            // We force reactivate and bring visible windows to the front.
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows {
                    if window.isVisible {
                        window.orderFrontRegardless()
                    }
                }
            }
        }
    }

    @objc private func showSettings() {
        SettingsWindowManager.shared.show()
    }

    static func relaunch() {
        let path = Bundle.main.bundlePath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        // Use a shell to sleep briefly and then open the app.
        // $0 in the script will be the path passed as the third argument.
        process.arguments = ["-c", "sleep 0.5; open \"$0\"", path]
        
        do {
            try process.run()
            // Using exit(0) to immediately quit the current process
            // so LaunchServices doesn't see a conflict.
            exit(0)
        } catch {
            print("Failed to relaunch application: \(error.localizedDescription)")
        }
    }
}
