import SwiftUI
import AppKit

class SuperKeyManager: ObservableObject {
    static let shared = SuperKeyManager()
    
    @AppStorage("enableSuperShortcut") private var isEnabled = true
    // Default to Command + Option (NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.option.rawValue)
    // Command = 1 << 20 (1048576), Option = 1 << 19 (524288) -> 1572864
    @AppStorage("superShortcutModifiers") private var modifierFlagsRaw = 1572864
    
    @Published var isActive = false
    @Published var inputText = ""
    
    private var hudWindow: NSPanel?
    private var monitor: Any?
    private var localMonitor: Any?
    
    private init() {
        setupMonitors()
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }
    
    private func setupMonitors() {
        // Global monitor for modifier changes (to detect trigger)
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            self?.handleEvent(event, source: "Global")
        }
        
        // Local monitor (in case app is active)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            self?.handleEvent(event, source: "Local")
            return event
        }
    }
    

    private func handleEvent(_ event: NSEvent, source: String) {
        // Run on Main Thread
        if Thread.isMainThread {
            processEvent(event, source: source)
        } else {
            DispatchQueue.main.async {
                self.processEvent(event, source: source)
            }
        }
    }
    
    private func processEvent(_ event: NSEvent, source: String) {
        guard self.isEnabled else { return }
        
        if event.type == .flagsChanged {
            self.handleFlagsChanged(event)
        } else if event.type == .keyDown && self.isActive {
             Logger.shared.log("[SuperKey] keyDown (\(source)) code: \(event.keyCode)")
            self.handleKeyDown(event)
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let currentModifiers = event.modifierFlags.rawValue
        
        let maskedModifiers = currentModifiers & ~NSEvent.ModifierFlags.capsLock.rawValue & ~NSEvent.ModifierFlags.numericPad.rawValue
        
        let targetModifiers = UInt(modifierFlagsRaw)
        
        if maskedModifiers == targetModifiers {
             if !isActive {
                 Logger.shared.log("[SuperKey] Matches target! Starting session...")
                 startSession()
             }
        } else {
            if isActive {
                if !inputText.isEmpty {
                    Logger.shared.log("[SuperKey] Modifiers released. Committing session. Input: \(inputText)")
                    commitAndClose()
                } else {
                    Logger.shared.log("[SuperKey] Modifiers released. Cancelling (empty input).")
                    cancelSession()
                }
            }
        }
    }
    
    private func handleKeyDown(_ event: NSEvent) {
        // Esc to cancel
        if event.keyCode == 53 { // ESC
            Logger.shared.log("[SuperKey] ESC pressed. Cancelling.")
            cancelSession()
            return
        }
        
        // Map KeyCode to Digit directly to avoid IME/Layout issues
        // Top Row 1-9 (18-25, 28) and 0 (29)
        // Numpad 0-9 (82-92, except 90 which is usually undefined/mixed)
        // Correct Numpad: 0=82, 1=83, 2=84, 3=85, 4=86, 5=87, 6=88, 7=89, 8=91, 9=92
        
        var num: Int? = nil
        
        switch event.keyCode {
        case 18: num = 1
        case 19: num = 2
        case 20: num = 3
        case 21: num = 4
        case 23: num = 5
        case 22: num = 6
        case 26: num = 7
        case 28: num = 8
        case 25: num = 9
        case 29: num = 0
            
        case 82: num = 0
        case 83: num = 1
        case 84: num = 2
        case 85: num = 3
        case 86: num = 4
        case 87: num = 5
        case 88: num = 6
        case 89: num = 7
        case 91: num = 8
        case 92: num = 9
        default:
            num = nil
        }
        
        if let digit = num {
            if inputText.count < 2 {
                Logger.shared.log("[SuperKey] Valid Digit input: \(digit)")
                self.inputText.append(String(digit))
            } else {
                 Logger.shared.log("[SuperKey] Input limit reached.")
            }
        } else {
            // Check modifiers again. If ONLY modifiers are pressed (unlikely for keyDown), ignore.
            // But keyDown usually means a non-modifier key.
            // If it's not a digit, and not a modifier key event (which flagsChanged handles), we cancel.
            // But wait, sometimes 'keyDown' events arrive for modifiers? No, usually flagsChanged.
            
            // Allow benign keys? No, strictly only allow digits.
            // But we must allow the *modifiers themselves* if they trigger repeat (unlikely on mac).
            
            // Explicitly check for "Delete" (51) to allow correction?
            if event.keyCode == 51 { // Delete
                 if !inputText.isEmpty {
                     inputText.removeLast()
                     Logger.shared.log("[SuperKey] Backspace.")
                 }
                 return
            }
            
            Logger.shared.log("[SuperKey] Invalid key code: \(event.keyCode). Cancelling.")
            cancelSession()
        }
    }
    
    private func startSession() {
        Logger.shared.log("[SuperKey] startSession() called")
        self.isActive = true
        self.inputText = ""
        self.showHUD()
    }
    
    private func cancelSession() {
        Logger.shared.log("[SuperKey] cancelSession() called")
        self.isActive = false
        self.inputText = ""
        self.hideHUD()
    }
    
    private func commitAndClose() {
        guard let minutes = Int(inputText), minutes > 0 else {
            cancelSession()
            return
        }
        
        let minVal = minutes
        self.hideHUD()
        self.isActive = false
        self.inputText = ""
        
        Logger.shared.log("[SuperKey] Posting CreateSuperKeyTimer notification with \(minVal) min")
        NotificationCenter.default.post(name: NSNotification.Name("CreateSuperKeyTimer"), object: nil, userInfo: ["minutes": minVal])
    }
    
    // MARK: - HUD Window Management
    
    private func showHUD() {
        Logger.shared.log("[SuperKey] showHUD() attempting...")
        
        if hudWindow == nil {
            Logger.shared.log("[SuperKey] Creating new NSPanel")
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                styleMask: [.borderless, .nonactivatingPanel], 
                backing: .buffered,
                defer: false
            )
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false // Disable system shadow to prevent "black line" artifact
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
            panel.center()
            panel.ignoresMouseEvents = true
            panel.isReleasedWhenClosed = false
            
            // Create Hosting View once
            let hostingView = NSHostingView(rootView: HUDWrapper(manager: self))
            hostingView.translatesAutoresizingMaskIntoConstraints = false
            hostingView.sizingOptions = .preferredContentSize // Allow it to size the window
            
            // Create a container view to hold the hosting view
            // This often helps stabilize layout for borderless windows
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
            containerView.addSubview(hostingView)
            
            NSLayoutConstraint.activate([
                hostingView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                hostingView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                // Let the hosting view determine its own size, don't pin to edges if not needed,
                // but for HUD we probably want it to fit.
                // Actually, let's pin edges so the window frame encompasses the view.
                hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
                hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            
            panel.contentView = containerView
            self.hudWindow = panel
            
            Logger.shared.log("[SuperKey] NSPanel initialized and contentView set")
        }
        
        // NO NOT Reset contentView here. It's already bound to 'self' (active instance).
        
        hudWindow?.center()
        Logger.shared.log("[SuperKey] Calling orderFront(nil)...")
        hudWindow?.orderFront(nil)
        Logger.shared.log("[SuperKey] orderFront(nil) Success!")
    }
    
    private func hideHUD() {
        Logger.shared.log("[SuperKey] hideHUD()")
        hudWindow?.orderOut(nil)
    }
    
    struct HUDWrapper: View {
        @ObservedObject var manager: SuperKeyManager
        var body: some View {
            SuperKeyHUDView(inputText: manager.inputText)
        }
    }
}
