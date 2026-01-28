import SwiftUI
import AppKit

struct ClickDraggableButton<Content: View>: NSViewRepresentable {
    var action: () -> Void
    var content: () -> Content
    
    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    func makeNSView(context: Context) -> DraggableView {
        let view = DraggableView()
        view.action = action
        
        // Host the SwiftUI content
        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    func updateNSView(_ nsView: DraggableView, context: Context) {
        nsView.action = action
        // Update hosted content if needed?
        // For static content (icon), it's fine. For rotating icon, we might need to update the rootView.
        // But simply recreating the hosting view might be expensive.
        // Let's try to update the rootView of the existing hostingView.
        if let hostingView = nsView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content()
        }
    }
    
    class DraggableView: NSView {
        var action: (() -> Void)?
        private var startLocation: NSPoint?
        private var hasDragged = false
        private var trackingArea: NSTrackingArea?
        
        override func updateTrackingAreas() {
            if let existing = trackingArea {
                removeTrackingArea(existing)
            }
            
            let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
            trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
            addTrackingArea(trackingArea!)
            super.updateTrackingAreas()
        }
        
        override func mouseEntered(with event: NSEvent) {
            // AUTO-ACTIVATE: As soon as the mouse touches the button, bring app to front!
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyAndOrderFront(nil)
        }
        
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
        
        override func mouseDown(with event: NSEvent) {
            // Redundant but safe: Ensure focus again on click
            self.window?.makeKeyAndOrderFront(nil)
            
            startLocation = event.locationInWindow
            hasDragged = false
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let start = startLocation else { return }
            let current = event.locationInWindow
            
            // Allow a small threshold before treating as drag
            if abs(current.x - start.x) > 2 || abs(current.y - start.y) > 2 {
                hasDragged = true
                self.window?.performDrag(with: event)
            }
        }
        
        override func mouseUp(with event: NSEvent) {
            if !hasDragged {
                action?()
            }
            // Reset
            startLocation = nil
            hasDragged = false
        }
    }
}
