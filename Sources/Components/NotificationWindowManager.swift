import SwiftUI
import AppKit

class NotificationWindowManager: NSObject {
    static let shared = NotificationWindowManager()
    
    private var window: NSPanel?
    
    // Callback retention
    private var currentOnSnooze: ((Int) -> Void)?
    private var currentOnDismiss: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func show(title: String, onSnooze: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        // Close existing if any
        close()
        
        self.currentOnSnooze = onSnooze
        self.currentOnDismiss = onDismiss
        
        // Create Panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 600), // SIGNIFICANTLY LARGER to accommodate shadow spread
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false 
        panel.ignoresMouseEvents = false
        
        // Floating level to stay on top
        panel.level = .floating 
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create Hosting Controller
        let contentView = NotificationBannerView(
            title: title,
            onSnooze: { [weak self] minutes in
                self?.currentOnSnooze?(minutes)
                self?.close()
            },
            onDismiss: { [weak self] in
                self?.currentOnDismiss?()
                self?.close()
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.wantsLayer = true // EXPLICIT for shadow rendering
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        
        // Center Horizontally, BOTTOM 20% Screen
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let panelWidth: CGFloat = 1200
            let panelHeight: CGFloat = 600
            
            let x = screenFrame.minX + (screenFrame.width - panelWidth) / 2
            let yCenter = screenFrame.minY + 25 // Bottom base Y (since window is huge, we offset the anchor)
            
            // Initial Frame (100px lower for slide up)
            panel.setFrame(NSRect(x: x, y: yCenter - 100, width: panelWidth, height: panelHeight), display: true)
            
            // Animation: Fade In + Slide UP
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.6
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1.0
                panel.animator().setFrame(NSRect(x: x, y: yCenter, width: panelWidth, height: panelHeight), display: true)
            }
        }
        
        self.window = panel
    }
    
    func close() {
        guard let panel = window else { return }
        
        // Slide down and fade out
        let currentFrame = panel.frame
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            panel.animator().alphaValue = 0
            panel.animator().setFrame(NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y - 50, width: currentFrame.width, height: currentFrame.height), display: true)
        }, completionHandler: {
            panel.close()
            self.window = nil
            self.currentOnSnooze = nil
            self.currentOnDismiss = nil
        })
    }
}
