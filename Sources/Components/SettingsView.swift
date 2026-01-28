import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Binding var isPresented: Bool
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("useFloatingIsland") private var useFloatingIsland = true
    @AppStorage("useSystemNotification") private var useSystemNotification = false
    
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
                    Text("设置")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Section: General
                        settingsSection(title: "通用") {
                            Toggle("开机自启动", isOn: $launchAtLogin)
                                .onChange(of: launchAtLogin) {
                                    toggleLaunchAtLogin(enabled: launchAtLogin)
                                }
                        }
                        
                        // Section: Notifications
                        settingsSection(title: "通知方式") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("悬浮岛 (灵动岛样式)", isOn: $useFloatingIsland)
                                    .disabled(!useSystemNotification && useFloatingIsland) // Must keep one
                                
                                Toggle("系统通知 (通知中心)", isOn: $useSystemNotification)
                                    .disabled(!useFloatingIsland && useSystemNotification) // Must keep one
                                    .onChange(of: useSystemNotification) {
                                        if useSystemNotification {
                                            NotificationManager.shared.requestAuthorization()
                                        }
                                    }
                                
                                if useSystemNotification {
                                    Button(action: {
                                        NotificationManager.shared.openNotificationSettings()
                                    }) {
                                        Text("打开系统通知设置...")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        if !useFloatingIsland && !useSystemNotification {
                            Text("请至少保留一种通知方式")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.8))
                                .padding(.top, -10)
                        }
                    }
                    .padding(20)
                }
            }
            .frame(width: 320, height: 380)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 320 * 0.42 / (320/50), style: .continuous)) // Proportional curvature
            // Actually, let's just use a fixed clean radius that feels right for the panel size
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .offset(dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            dragOffset = .zero
                        }
                    }
            )
        }
        .transition(.scale(scale: 0.9).combined(with: .opacity))
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            
            VStack {
                content()
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
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
