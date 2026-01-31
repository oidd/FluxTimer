import SwiftUI
import AppKit

struct ClickDraggableButton<Content: View>: NSViewRepresentable {
    var action: () -> Void
    @Binding var isPressed: Bool
    var content: () -> Content
    
    init(action: @escaping () -> Void, isPressed: Binding<Bool> = .constant(false), @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self._isPressed = isPressed
        self.content = content
    }
    
    func makeNSView(context: Context) -> DraggableView {
        let view = DraggableView()
        view.action = action
        view.isPressed = $isPressed
        
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
        nsView.isPressed = $isPressed
        
        if let hostingView = nsView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content()
        }
    }
    
    class DraggableView: NSView {
        var action: (() -> Void)?
        var isPressed: Binding<Bool>?
        
        private var initialMouseLocation: NSPoint?
        private var initialWindowFrame: NSRect?
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
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyAndOrderFront(nil)
        }
        
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
        
        override func mouseDown(with event: NSEvent) {
            self.window?.makeKeyAndOrderFront(nil)
            
            // For click-through or action
            hasDragged = false
            
            // Store initial state for manual dragging
            initialMouseLocation = NSEvent.mouseLocation
            initialWindowFrame = self.window?.frame
            
            DispatchQueue.main.async {
                self.isPressed?.wrappedValue = true
            }
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let window = self.window,
                  let initialMouse = initialMouseLocation,
                  let initialFrame = initialWindowFrame else { return }
            
            let currentMouse = NSEvent.mouseLocation
            let deltaX = currentMouse.x - initialMouse.x
            let deltaY = currentMouse.y - initialMouse.y
            
            // Only consider it a drag if moved significantly
            if !hasDragged && (abs(deltaX) > 2 || abs(deltaY) > 2) {
                hasDragged = true
            }
            
            if hasDragged {
                var newFrame = initialFrame
                newFrame.origin.x += deltaX
                newFrame.origin.y += deltaY
                
                // SAFETY CLAMP: Ensure the button (at y:40 in window) remains clickable.
                // Button bottom is at height - 90. We want this to be at least 20px below screen top.
                if let screen = window.screen {
                    let screenTop = screen.visibleFrame.maxY
                    let buttonScreenBottom = newFrame.origin.y + newFrame.size.height - 90
                    
                    if buttonScreenBottom > screenTop - 20 {
                        newFrame.origin.y = screenTop - 20 - (newFrame.size.height - 90)
                    }
                }
                
                // Set frame manually to bypass performDrag constraints
                window.setFrame(newFrame, display: true, animate: false)
            }
        }
        
        override func mouseUp(with event: NSEvent) {
            DispatchQueue.main.async {
                self.isPressed?.wrappedValue = false
            }
            
            if !hasDragged {
                action?()
            }
            initialMouseLocation = nil
            initialWindowFrame = nil
            hasDragged = false
        }
    }
}
