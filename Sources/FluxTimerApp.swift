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
        // Initialize Managers
        _ = NotificationManager.shared
        _ = SuperKeyManager.shared
        
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
        
        floatingPanel?.contentView = ClickThroughHostingView(rootView: contentView)
        floatingPanel?.center() // Center on screen initially
        floatingPanel?.makeKeyAndOrderFront(nil)
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
