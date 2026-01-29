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
            NSApp.activate(ignoringOtherApps: true)
            self.window?.makeKeyAndOrderFront(nil)
        }
        
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
        
        override func mouseDown(with event: NSEvent) {
            self.window?.makeKeyAndOrderFront(nil)
            
            startLocation = event.locationInWindow
            hasDragged = false
            
            DispatchQueue.main.async {
                self.isPressed?.wrappedValue = true
            }
        }
        
        override func mouseDragged(with event: NSEvent) {
            guard let start = startLocation else { return }
            let current = event.locationInWindow
            
            if abs(current.x - start.x) > 2 || abs(current.y - start.y) > 2 {
                hasDragged = true
                self.window?.performDrag(with: event)
            }
        }
        
        override func mouseUp(with event: NSEvent) {
            DispatchQueue.main.async {
                self.isPressed?.wrappedValue = false
            }
            
            if !hasDragged {
                action?()
            }
            startLocation = nil
            hasDragged = false
        }
    }
}
