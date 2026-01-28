import SwiftUI
import AppKit

@main
struct FluxTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
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
        // Create the floating panel
        let contentView = ContentView()
        
        floatingPanel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 600), // Expanded for Drag buffer
            backing: .buffered,
            defer: false
        )
        
        floatingPanel?.contentView = ClickThroughHostingView(rootView: contentView)
        floatingPanel?.center() // Center on screen initially
        floatingPanel?.makeKeyAndOrderFront(nil)
    }
}
