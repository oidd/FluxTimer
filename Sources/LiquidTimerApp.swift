import SwiftUI
import AppKit

@main
struct LiquidTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var floatingPanel: FloatingPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the floating panel
        let contentView = ContentView()
        
        floatingPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400), // Increased size to prevent clipping during animation
            backing: .buffered,
            defer: false
        )
        
        floatingPanel?.contentView = NSHostingView(rootView: contentView)
        floatingPanel?.center() // Center on screen initially
        floatingPanel?.makeKeyAndOrderFront(nil)
    }
}
