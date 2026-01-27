import SwiftUI
import AppKit

struct WindowDragger: ViewModifier {
    @State private var startLocation: NSPoint? = nil
    
    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard let window = NSApp.windows.first(where: { $0.level == .floating }) else { return }
                    
                    if startLocation == nil {
                        startLocation = value.startLocation
                    }
                    
                    // We need to move the window.
                    // The 'value.translation' is total offset from start.
                    // If we knew the window origin at start, we could just set origin = startOrigin + translation.
                    // But we don't want to store window frame in State if we can avoid it.
                    
                    // Better approach: Track previous translation
                    // But 'value' doesn't give previous.
                    
                    // Standard MacOS approach:
                    // Use NSEvent.mouseLocation and compute delta manually?
                    
                    // Let's try:
                    // Current Screen Mouse - Initial Screen Mouse = Delta
                    // Window Origin = Initial Window Origin + Delta.
                    // This requires capturing Initial Window Origin.
                    
                    // Let's use a specialized NSView wrapper for "mouseDown" based dragging -> standard appkit behavior
                    // But for pure SwiftUI:
                    // We need to store 'initialWindowOrigin'
                    // We can't easily do that in .onChanged because it fires repeatedly.
                    // We need .onChanged to check "isFirst?"
                }
        )
        // Actually, the simplest way for a frameless window is to subclass NSView, override mouseDown, and call window?.performDrag(with: event).
        // Let's replace this Modifier with a NSViewRepresentable that acts as a Drag Handle.
        .overlay(
            WindowDragHandler()
        )
    }
}

struct WindowDragHandler: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView {
        return DragView()
    }
    
    func updateNSView(_ nsView: DragView, context: Context) {}
    
    class DragView: NSView {
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
            return true
        }
        
        override func mouseDown(with event: NSEvent) {
            self.window?.performDrag(with: event)
        }
    }
}
