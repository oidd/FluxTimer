import SwiftUI
import AppKit

class SettingsPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
}

class SettingsWindowManager: NSObject, ObservableObject {
    static let shared = SettingsWindowManager()
    
    private var window: SettingsPanel?
    
    private override init() {
        super.init()
    }
    
    func show() {
        if window == nil {
            let panel = SettingsPanel(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 620),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            panel.minSize = NSSize(width: 440, height: 620)
            panel.maxSize = NSSize(width: 440, height: 620)
            
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.level = .floating
            panel.isMovableByWindowBackground = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.isReleasedWhenClosed = false
            
            // Disable native minimize and zoom to make them gray
            panel.standardWindowButton(.miniaturizeButton)?.isEnabled = false
            panel.standardWindowButton(.zoomButton)?.isEnabled = false
            
            let hostingView = NSHostingView(rootView: DynamicSettingsView())
            // Ensure hosting view doesn't have a background
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            
            panel.contentView = hostingView
            panel.center()
            
            // Shift traffic lights for better spacing (down and right)
            if let titlebarView = panel.standardWindowButton(.closeButton)?.superview {
                let currentFrame = titlebarView.frame
                titlebarView.setFrameOrigin(NSPoint(x: 16, y: currentFrame.origin.y - 8))
            }
            
            panel.invalidateShadow()
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
