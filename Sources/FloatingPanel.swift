import AppKit
import SwiftUI

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView], backing: backing, defer: flag)
        
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false // swiftUI view handles shadow
        self.isMovableByWindowBackground = false // Disable global drag to allow component gestures
    }
    
    override var canBecomeKey: Bool {
        return true // Needed for input fields to work
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
