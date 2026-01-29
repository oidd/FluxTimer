import SwiftUI
import AppKit

class SettingsWindowManager: NSObject, ObservableObject {
    static let shared = SettingsWindowManager()
    
    private var window: NSPanel?
    
    private override init() {
        super.init()
    }
    
    func show() {
        if window == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
                styleMask: [.borderless, .nonactivatingPanel, .resizable],
                backing: .buffered,
                defer: false
            )
            
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isReleasedWhenClosed = false
            
            let hostingView = NSHostingView(rootView: DynamicSettingsView())
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            
            panel.contentView = hostingView
            panel.center()
            
            self.window = panel
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func close() {
        window?.orderOut(nil)
    }
    
    func isVisible() -> Bool {
        return window?.isVisible ?? false
    }
}

struct DynamicSettingsView: View {
    var body: some View {
        SettingsView(isPresented: Binding(
            get: { SettingsWindowManager.shared.isVisible() },
            set: { newValue in
                if !newValue {
                    SettingsWindowManager.shared.close()
                }
            }
        ))
    }
}
