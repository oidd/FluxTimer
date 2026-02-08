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
        let hostingView = FirstMouseHostingView(rootView: content())
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
        
        if let hostingView = nsView.subviews.first as? FirstMouseHostingView<Content> {
            hostingView.rootView = content()
        }
    }
    
    // Custom Hosting View to allow click-through (acceptsFirstMouse)
    private class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
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
            // FORCE ACTIVATE on click to resolve "double click needed" issues
            NSApp.activate(ignoringOtherApps: true)
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
                
                if let screen = window.screen {
                    let visibleFrame = screen.visibleFrame
                    
                    // Button Geometry relative to Window (1000x800)
                    // Button X: 475, Width: 50 -> Range [475, 525]
                    // Button Y from top: 40, Height: 50 -> Top: Height-40, Bottom: Height-90
                    // Window Height: 800
                    
                    let buttonOffsetX: CGFloat = 475
                    let buttonWidth: CGFloat = 50
                    let buttonOffsetYFromTop: CGFloat = 40
                    let buttonHeight: CGFloat = 50
                    
                    // 1. Calculate Button's Global Frame
                    let buttonGlobalLeft = newFrame.origin.x + buttonOffsetX
                    let buttonGlobalRight = buttonGlobalLeft + buttonWidth
                    
                    let windowTop = newFrame.origin.y + newFrame.size.height
                    let buttonGlobalTop = windowTop - buttonOffsetYFromTop
                    let buttonGlobalBottom = buttonGlobalTop - buttonHeight
                    
                    // 2. Clamp Horizontal (Left / Right)
                    // Left Edge
                    if buttonGlobalLeft < visibleFrame.minX {
                        newFrame.origin.x = visibleFrame.minX - buttonOffsetX
                    }
                    // Right Edge
                    if buttonGlobalRight > visibleFrame.maxX {
                        newFrame.origin.x = visibleFrame.maxX - buttonOffsetX - buttonWidth
                    }
                    
                    // 3. Clamp Vertical (Top / Bottom)
                    // Top Edge (Keep button inside visible area)
                    if buttonGlobalTop > visibleFrame.maxY {
                        newFrame.origin.y = visibleFrame.maxY - newFrame.size.height + buttonOffsetYFromTop
                    }
                    
                    // Bottom Edge
                    if buttonGlobalBottom < visibleFrame.minY {
                        newFrame.origin.y = visibleFrame.minY - newFrame.size.height + buttonOffsetYFromTop + buttonHeight
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
            } else {
                // Save position after drag
                if let window = self.window {
                    let originString = NSStringFromPoint(window.frame.origin)
                    UserDefaults.standard.set(originString, forKey: "windowPosition")
                }
            }
            
            initialMouseLocation = nil
            initialWindowFrame = nil
            hasDragged = false
        }
    }
}
