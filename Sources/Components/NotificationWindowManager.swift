import SwiftUI
import AppKit

class NotificationWindowManager: NSObject {
    static let shared = NotificationWindowManager()
    
    private var activePanels: [NSPanel] = []
    
    override init() {
        super.init()
    }
    
    func show(title: String, onSnooze: @escaping (Int) -> Void, onDismiss: @escaping () -> Void) {
        // Create Panel
        let panelWidth: CGFloat = 1100 // Slightly wider to ensure shadow doesn't clip
        let panelHeight: CGFloat = 200 // Tall enough for shadow spread
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false 
        panel.ignoresMouseEvents = false
        panel.level = .floating 
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create Hosting Controller
        let contentView = NotificationBannerView(
            title: title,
            onSnooze: { minutes in
                onSnooze(minutes)
                self.close(panel)
            },
            onDismiss: {
                onDismiss()
                self.close(panel)
            }
        )
        
        let hostingView = NSHostingView(rootView: contentView.preferredColorScheme(.dark))
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hostingView
        
        // Position & Stacking
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            
            // Newer on Bottom, Older pop UP
            let stackGap: CGFloat = 130.0
            let yBase = screenFrame.minY + screenFrame.height * 0.25 // "Middle-bottom" zone
            
            for (idx, existingPanel) in activePanels.enumerated() {
                let x = existingPanel.frame.origin.x
                let targetY = yBase + CGFloat(idx + 1) * stackGap
                existingPanel.animator().setFrame(NSRect(x: x, y: targetY, width: panelWidth, height: panelHeight), display: true)
            }
            
            // New panel at base position
            activePanels.insert(panel, at: 0)
            
            let x = screenFrame.minX + (screenFrame.width - panelWidth) / 2
            
            // Initial Frame (Pop up from slightly below base)
            panel.setFrame(NSRect(x: x, y: yBase - 40, width: panelWidth, height: panelHeight), display: true)
            panel.alphaValue = 0
            panel.makeKeyAndOrderFront(nil)
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().alphaValue = 1.0
                panel.animator().setFrame(NSRect(x: x, y: yBase, width: panelWidth, height: panelHeight), display: true)
            }
        }
    }
    
    func close(_ panel: NSPanel) {
        if let index = activePanels.firstIndex(of: panel) {
            activePanels.remove(at: index)
        }
        
        let currentFrame = panel.frame
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            panel.animator().alphaValue = 0
            panel.animator().setFrame(NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y - 40, width: currentFrame.width, height: currentFrame.height), display: true)
        }, completionHandler: {
             panel.close()
        })
    }
}
