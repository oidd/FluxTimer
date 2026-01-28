import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("useFloatingIsland") private var useFloatingIsland = true
    @AppStorage("useSystemNotification") private var useSystemNotification = false
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .auto
    private let l10n = LocalizationManager.shared
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background Dimmer (Invisble but functional for tap-to-dismiss)
            Color.black.opacity(0.001)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isPresented = false
                    }
                }
            
            // Settings Panel
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(l10n.t("设置"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                VStack(spacing: 8) {
                    // Row: General
                    settingsRow(title: l10n.t("开机自启动")) {
                        Toggle("", isOn: $launchAtLogin)
                            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                            .onChange(of: launchAtLogin) { newValue in
                                toggleLaunchAtLogin(enabled: newValue)
                            }
                            .labelsHidden()
                    }
                    
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
                    }
                    
                    // Row: Notification Method (Consolidated)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(l10n.t("通知方式"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            HStack(spacing: 24) {
                                Toggle(l10n.t("悬浮岛 (灵动岛样式)"), isOn: $useFloatingIsland)
                                    .toggleStyle(CheckboxToggleStyle())
                                
                                Toggle(l10n.t("系统通知 (通知中心)"), isOn: $useSystemNotification)
                                    .toggleStyle(CheckboxToggleStyle())
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
                                
                                Spacer()
                                
                                if !useFloatingIsland && !useSystemNotification {
                                    Text(l10n.t("请至少保留一种通知方式"))
                                        .font(.system(size: 10))
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 440, height: 300) // Slightly wider and shorter to fit all
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 15)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = .zero
                        }
                    }
            )
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.92).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
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
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
}
