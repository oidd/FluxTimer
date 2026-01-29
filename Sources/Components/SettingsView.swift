import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("useFloatingIsland") private var useFloatingIsland = true
    @AppStorage("useSystemNotification") private var useSystemNotification = false
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .auto
    @AppStorage("enableSound") private var enableSound = true
    
    // Snooze Options
    @AppStorage("snoozeOption1") private var snoozeOption1: Int = 1
    @AppStorage("snoozeOption2") private var snoozeOption2: Int = 5
    @AppStorage("snoozeOption3") private var snoozeOption3: Int = 30
    @AppStorage("autoDismiss30s") private var autoDismiss30s = true
    
    // Super Shortcut
    @AppStorage("enableSuperShortcut") private var enableSuperShortcut = true
    @AppStorage("superShortcutModifiers") private var superShortcutModifiers = 1572864 // Cmd + Opt
    @State private var isRecordingShortcut = false
    
    private let l10n = LocalizationManager.shared
    @State private var isAccessibilityTrusted = AXIsProcessTrusted()
    
    // Poll permission changes
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0) {
            // Space for Traffic Lights
            Spacer()
                .frame(height: 48)
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 8) {
                    // Section Header: General
                    Text(l10n.t("常规"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    settingsGroup {
                        // Row: General
                        settingsRow(title: l10n.t("开机自启动")) {
                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                .onChange(of: launchAtLogin) { newValue in
                                    toggleLaunchAtLogin(enabled: newValue)
                                }
                                .labelsHidden()
                        }
                        
                        Divider().overlay(Color.white.opacity(0.1)).padding(.horizontal, 16)
                        
                        // Row: Language
                        settingsRow(title: l10n.t("语言")) {
                            Picker("", selection: $appLanguage) {
                                ForEach(AppLanguage.allCases, id: \.self) { lang in
                                    Text(lang.pickerName).tag(lang)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 110)
                            .onChange(of: appLanguage) { _ in
                                LocalizationManager.shared.notifyLanguageChange()
                            }
                        }
                        
                        Divider().overlay(Color.white.opacity(0.1)).padding(.horizontal, 16)
                        
                        // Row: Prompt Sound
                        settingsRow(title: l10n.t("提示音效")) {
                            Toggle("", isOn: $enableSound)
                                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                .labelsHidden()
                        }
                        
                        Divider().overlay(Color.white.opacity(0.1)).padding(.horizontal, 16)
                        
                        // Row: Super Shortcut
                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(l10n.t("超级快捷键"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary.opacity(0.9))
                                    
                                    Text(l10n.t("按住快捷键并点按数字，快速创建倒计时"))
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary.opacity(0.8))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $enableSuperShortcut)
                                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            
                            if enableSuperShortcut {
                                HStack {
                                    Text(l10n.t("快捷键组合"))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary.opacity(0.9))
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        isRecordingShortcut = true
                                    }) {
                                        Text(isRecordingShortcut ? l10n.t("按下两个修饰键...") : ModifierKeyUtils.readable(from: superShortcutModifiers))
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(isRecordingShortcut ? .accentColor : .primary.opacity(0.8))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(isRecordingShortcut ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                    .background(
                                        Group {
                                            if isRecordingShortcut {
                                                ActivityMonitorView(isRecording: $isRecordingShortcut, modifierFlags: $superShortcutModifiers)
                                                    .frame(width: 0, height: 0)
                                            }
                                        }
                                    )
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                
                                // Permission Warning
                                if !isAccessibilityTrusted {
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 12))
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(l10n.t("需要辅助功能权限"))
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Text(l10n.t("以监听全局快捷键，请在“系统设置 > 隐私与安全性 > 辅助功能”中开启。"))
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            Button(action: {
                                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                                    NSWorkspace.shared.open(url)
                                                }
                                                checkAccessibility()
                                            }) {
                                                Text(l10n.t("打开设置"))
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.blue)
                                            }
                                            .buttonStyle(.plain)
                                            .padding(.top, 2)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 12)
                                }
                            }
                        }
                    }
                    
                    // Extend Time moved to floating island group
                    
                    // Row: Notification Method (Consolidated)
                    Text(l10n.t("通知方式"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    settingsGroup {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 24) {
                                    Toggle(l10n.t("悬浮岛"), isOn: $useFloatingIsland)
                                        .toggleStyle(CheckboxToggleStyle())
                                        .disabled(useFloatingIsland && !useSystemNotification) // Only disable if it's the LAST one ON
                                    
                                    Toggle(l10n.t("系统通知"), isOn: $useSystemNotification)
                                        .toggleStyle(CheckboxToggleStyle())
                                        .disabled(useSystemNotification && !useFloatingIsland) // Only disable if it's the LAST one ON
                                        .onChange(of: useSystemNotification) { newValue in
                                            if newValue {
                                                NotificationManager.shared.requestAuthorization { granted in
                                                    if !granted {
                                                        // Fallback UI or guidance could be here, 
                                                        // but for now we just log and let user see it's not working if they denied
                                                        print("System notification permission was not granted.")
                                                    }
                                                }
                                            }
                                        }
                                        
                                    Spacer()
                                }
                                .onAppear {
                                    // Auto-recovery: If both are somehow off (legacy state), force one on
                                    if !useFloatingIsland && !useSystemNotification {
                                        useFloatingIsland = true
                                    }
                                }
                                
                                HStack {
                                    Button(action: {
                                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }) {
                                        Text(l10n.t("打开系统通知设置..."))
                                            .font(.system(size: 11))
                                            .foregroundColor(.blue.opacity(0.8))
                                    }
                                    .buttonStyle(.plain)
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .padding(.top, 4)

                    // NEW GROUP: Floating Island Settings
                    if useFloatingIsland {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(l10n.t("悬浮岛"))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            settingsGroup {
                                // 1. Extend Time (Moved here)
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(l10n.t("延长计时"))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary.opacity(0.9))
                                        
                                        Text(l10n.t("用于悬浮岛上快捷延长计时时间"))
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 8) {
                                        snoozeInput(value: $snoozeOption1)
                                        snoozeInput(value: $snoozeOption2)
                                        snoozeInput(value: $snoozeOption3)
                                        Text(l10n.t("分钟"))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                
                                Divider().overlay(Color.white.opacity(0.1)).padding(.horizontal, 16)
                                
                                // 2. Auto Dismiss Toggle
                                settingsRow(title: l10n.t("30秒自动关闭")) {
                                    Toggle("", isOn: $autoDismiss30s)
                                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                        .labelsHidden()
                                }
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(white: 1.0, opacity: 0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 15)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
        .onReceive(timer) { _ in
            checkAccessibility()
        }
        .ignoresSafeArea(.all)
    }
    
    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func settingsRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary.opacity(0.9))
            
            Spacer()
            
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }
    
    private func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                print("Launch at login enabled")
            } else {
                try SMAppService.mainApp.unregister()
                print("Launch at login disabled")
            }
        } catch {
            print("Failed to toggle launch at login: \(error.localizedDescription)")
            // Fallback: If it's already registered or unregistered, it might throw
        }
    }
    
    private func snoozeInput(value: Binding<Int>) -> some View {
        TextField("", value: value, formatter: NumberFormatter())
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .padding(.vertical, 4)
            .frame(width: 40)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }

    private func checkAccessibility() {
        isAccessibilityTrusted = AXIsProcessTrusted()
    }
}

// Helper to display modifiers
struct ModifierKeyUtils {
    static func readable(from flags: Int) -> String {
        var str = ""
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(flags))
        
        if modifierFlags.contains(.control) { str += "⌃ " }
        if modifierFlags.contains(.option) { str += "⌥ " }
        if modifierFlags.contains(.shift) { str += "⇧ " }
        if modifierFlags.contains(.command) { str += "⌘ " }
        
        return str.trimmingCharacters(in: .whitespaces)
    }
}

// Representable to monitor keys locally for recording
struct ActivityMonitorView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var modifierFlags: Int
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if isRecording {
            DispatchQueue.main.async {
                // Ensure the view is in the window hierarchy before making it first responder
                if nsView.window != nil {
                     nsView.window?.makeFirstResponder(context.coordinator)
                }
            }
        } else {
             // Ensure we stop recording if state changes externally
             DispatchQueue.main.async {
                 if nsView.window?.firstResponder == context.coordinator {
                     nsView.window?.makeFirstResponder(nil)
                 }
             }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSResponder {
        var parent: ActivityMonitorView
        
        init(parent: ActivityMonitorView) {
            self.parent = parent
            super.init()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        // Need to become first responder to receive flagsChanged
        override var acceptsFirstResponder: Bool { true }
        
        override func flagsChanged(with event: NSEvent) {
            guard parent.isRecording else { return }
            
            let currentModifiers = event.modifierFlags.rawValue
            let masked = currentModifiers & ~NSEvent.ModifierFlags.capsLock.rawValue & ~NSEvent.ModifierFlags.numericPad.rawValue
            
            // Allow user to check what they are pressing
            // If they press and release without 2 keys, we might need logic.
            // Requirement: "Must be two modifier keys"
            
            // Check count of bits set?
            // Command=1<<20, Option=1<<19, Control=1<<18, Shift=1<<17
            var count = 0
            if (masked & NSEvent.ModifierFlags.command.rawValue) != 0 { count += 1 }
            if (masked & NSEvent.ModifierFlags.option.rawValue) != 0 { count += 1 }
            if (masked & NSEvent.ModifierFlags.control.rawValue) != 0 { count += 1 }
            if (masked & NSEvent.ModifierFlags.shift.rawValue) != 0 { count += 1 }
            
            if count == 2 {
                // Success
                let exactModifiers = Int(masked)
                DispatchQueue.main.async {
                    self.parent.modifierFlags = exactModifiers
                    self.parent.isRecording = false
                    // Resign first responder to stop monitoring locally
                    self.resignFirstResponder()
                }
            }
        }
    }
}
