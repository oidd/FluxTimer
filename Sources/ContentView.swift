import SwiftUI
import AppKit

// MULTI-TIMER MODEL
// MULTI-TIMER MODEL
struct RunningTimer: Identifiable, Equatable {
    let id = UUID()
    var totalTime: TimeInterval
    var remainingTime: TimeInterval
    var isFinished: Bool = false
    var hasNotified: Bool = false // Track notification state
    var title: String
}

// Layout mode enum for horizontal/vertical arrangement
enum LayoutMode: String, CaseIterable {
    case horizontal = "horizontal"
    case vertical = "vertical"
}

struct ContentView: View {
    enum AppState {
        case idle // Plus button only
        case setting // Expanded capsule
        case running // Countdown active
        case finished // Ripple effect
    }
    
    // APP STATE
    @State private var appState: AppState = .idle
    @State private var minutes: Int = 0
    @State private var timerTitle: String = ""
    @State private var isDragging = false
    @State private var showPresets = false // Sequenced waterfall state
    @State private var shimmerProgress: CGFloat = -1.0 // Shimmer sweep (-1 to 1)
    
    // MULTI-TIMER STATE
    @State private var runningTimers: [RunningTimer] = []
    @State private var hoverLockout = false // Prevent unintended hover during transitions
    @State private var isLayoutTransitioning = false // For layout switch animation
    
    @State private var savedPresets: [TimerPreset] = [
        TimerPreset(minutes: 5, title: LocalizationManager.shared.t("休息一下")),
        TimerPreset(minutes: 25, title: LocalizationManager.shared.t("番茄专注"))
    ]
    
    // PERSISTENT SETTINGS
    @AppStorage("isAlwaysOnTop") private var isAlwaysOnTop = true
    @AppStorage("useFloatingIsland") private var useFloatingIsland = true
    @AppStorage("useSystemNotification") private var useSystemNotification = false
    @AppStorage("enableSound") private var enableSound = true
    @State private var isButtonDragging = false
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .auto
    @AppStorage("enableLastRecord") private var enableLastRecord = true
    @AppStorage("lastRecordMinutes") private var lastRecordMinutes: Int = 0
    @AppStorage("lastRecordTitle") private var lastRecordTitle: String = ""
    @AppStorage("layoutMode") private var layoutMode: LayoutMode = .horizontal
    @State private var isHidingForSwitch = false // For sequential layout switch animation

    
    private let l10n = LocalizationManager.shared
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let dragLogic = DragLogic()
    
    var body: some View {
        // ROOT CANVAS: 800x600 Fixed
        // WE USE ABSOLUTE POSITIONING (OFFSETS) to guarantee NO shifts.
        // Center X = 400.
        // Button Width = 50. Half = 25.
        // Button X Range = [375, 425].
        // Spacing = 12.
        
        ZStack(alignment: .topLeading) {
            
            // 1. TIMERS CONTAINER
            Group {
                if layoutMode == .horizontal {
                    // HORIZONTAL: Timers on the left, growing leftwards
                    HStack(spacing: 12) {
                        Spacer()
                        if !isHidingForSwitch {
                            ForEach($runningTimers) { $timer in
                                RunningTimerView(timer: $timer, hoverLockout: $hoverLockout, layoutMode: .horizontal, onStop: {
                                     stopTimer(timer)
                                })
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.trailing, 62) // Gap from button at x=500
                    .frame(width: 525, height: 80, alignment: .trailing) 
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 0.15),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: 0, y: 25)
                    .transition(.identity)
                } else {
                    // VERTICAL: Timers BELOW the button
                    VStack(alignment: .leading, spacing: 12) {
                        if !isHidingForSwitch {
                            ForEach($runningTimers.reversed()) { $timer in
                                RunningTimerView(timer: $timer, hoverLockout: $hoverLockout, layoutMode: .vertical, onStop: {
                                     stopTimer(timer)
                                })
                                .frame(width: 250, alignment: .leading)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        Spacer()
                    }
                    .padding(.leading, 8)
                    .padding(.top, 62) // Gap from button bottom (40+50)
                    .frame(width: 260, height: 500, alignment: .top)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black, location: 0.85),
                                .init(color: .clear, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(x: 467, y: 40)
                    .transition(.identity)
                }
            }
            .zIndex(10)
            
            // 2. CENTER ANCHOR (Button + Presets)
            // Starts at x = 375.
            VStack(alignment: .leading, spacing: 0) {
                // BUTTON
                ZStack {
                    RoundedRectangle(cornerRadius: 50 * 0.42, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(RoundedRectangle(cornerRadius: 50 * 0.42, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    ZStack {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .medium, design: .rounded)) // Thicker, simplified icon
                            .foregroundColor(appState == .idle ? .primary : .white) // Adapt color
                            .rotationEffect(.degrees(appState == .idle ? 0 : 45)) // Rotate 45 deg (minimal) to become X
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appState)
                    }
                    
                    ClickDraggableButton(action: {
                        DispatchQueue.main.async {
                            if appState == .idle {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    appState = .setting
                                    minutes = 0
                                }
                                // Expand Waterfall stage 2
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        showPresets = true
                                    }
                                }
                            } else {
                                // Collapse Waterfall stage 1
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showPresets = false
                                }
                                // Collapse stage 2
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        appState = .idle
                                        timerTitle = "" // Clear text on collapse
                                    }
                                }
                            }
                        }
                    }, isPressed: $isButtonDragging) {
                        Color.clear.contentShape(Circle())
                    }
                }
                .frame(width: 50, height: 50)
                .scaleEffect(isButtonDragging ? 0.92 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isButtonDragging)
                .overlay(
                    // SHIMMER LIGHT SWEEP
                    GeometryReader { geo in
                        let w = geo.size.width
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(0.4), location: 0.5),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .frame(width: w * 2, height: w * 2)
                        .offset(x: w * shimmerProgress, y: -w * shimmerProgress)
                    }
                    .allowsHitTesting(false)
                )
                .clipShape(RoundedRectangle(cornerRadius: 50 * 0.42, style: .continuous)) // Apply clip AFTER overlay
                .contextMenu {
                    Toggle(l10n.t("始终置顶"), isOn: $isAlwaysOnTop)
                    
                    Divider()
                    
                    Picker(selection: Binding(
                        get: { layoutMode },
                        set: { newMode in
                            switchLayoutMode(to: newMode)
                        }
                    ), label: EmptyView()) {
                        Text(l10n.t("横向") + l10n.t("布局"))
                            .tag(LayoutMode.horizontal)
                        
                        Text(l10n.t("纵向") + l10n.t("布局"))
                            .tag(LayoutMode.vertical)
                    }
                    .pickerStyle(.inline)
                    
                    Divider()
                    
                    Button(l10n.t("设置")) {
                        SettingsWindowManager.shared.show()
                    }
                    
                    Divider()
                    
                    Button(l10n.t("退出")) {
                        NSApp.terminate(nil)
                    }
                }
                .onHover { hovering in
                    if hovering {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            shimmerProgress = 1.0 // Sweep to top-right
                        }
                    } else {
                        // BACK SWEEP: Only if we didn't click and expand
                        if appState == .idle {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                shimmerProgress = -1.0 // Sweep back to bottom-left
                            }
                        } else {
                            // Instant reset if expanded
                            shimmerProgress = -1.0
                        }
                    }
                }
            }
            // Button position: y:40 (Provides space for labels above)
            .offset(x: 475, y: 40)
            .zIndex(100) // Always on Top
            .id("mainButton") // Fixed ID to prevent re-render on timer updates
            
            // 3. RIGHT WING (Capsule)
            // Starts at x = 437 (425 + 12)
            ZStack(alignment: .topLeading) {
                if appState == .setting || isDragging {
                    VStack(alignment: .leading, spacing: 5) {
                        DragCapsuleView(
                            minutes: $minutes,
                            isDragging: $isDragging,
                            title: $timerTitle,
                            isFavorite: savedPresets.contains { $0.minutes == minutes && $0.title == (timerTitle.isEmpty ? l10n.t("自定义") : timerTitle) },
                            dragChanged: { translation in
                                self.minutes = dragLogic.minutes(for: translation)
                            },
                            dragEnded: {
                            },
                            onCommit: {
                                if minutes > 0 {
                                    startNewTimer()
                                }
                            },
                            onFavoriteToggle: {
                                togglePreset()
                            }
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .leading)))
                        
                        // PRESET LIST (Now specifically shown under the capsule)
                            PresetListView(
                                isVisible: showPresets, 
                                isFullVisibility: true, 
                                presets: $savedPresets,
                                lastRecord: enableLastRecord && lastRecordMinutes > 0 ? TimerPreset(minutes: lastRecordMinutes, title: lastRecordTitle) : nil,
                                onSelect: { preset in
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        self.minutes = preset.minutes
                                        self.timerTitle = preset.title
                                        startNewTimer()
                                    }
                                },
                                onDelete: { preset in
                                    deletePreset(preset)
                                },
                                onFavoriteLast: { preset in
                                    // Toggle favorite status
                                    if let index = self.savedPresets.firstIndex(where: { $0.minutes == preset.minutes && $0.title == preset.title }) {
                                        withAnimation {
                                            _ = self.savedPresets.remove(at: index)
                                        }
                                    } else {
                                        withAnimation {
                                            self.savedPresets.append(preset)
                                        }
                                    }
                                }
                            )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            // Right wing position: fixed with button y:40
            .offset(x: 537, y: 40)
            .zIndex(50) // Behind button, in front of background
            

        }
        // Zero-Wall window frame (1000x800)
        .frame(width: 1000, height: 800, alignment: .topLeading)
        .onAppear {
            updateWindowLevel()
            NotificationManager.shared.requestAuthorization()
            
            // Load Presets
            if let loaded = PersistenceManager.shared.loadPresets() {
                withAnimation {
                    savedPresets = loaded
                }
            }
        }
        .onChange(of: savedPresets) { newValue in
            PersistenceManager.shared.savePresets(newValue)
        }
        .onChange(of: isAlwaysOnTop) { _ in
            updateWindowLevel()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CreateSuperKeyTimer"))) { notification in
            if let mins = notification.userInfo?["minutes"] as? Int {
                // Directly start timer with default title if needed
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.minutes = mins
                    self.timerTitle = l10n.t("流光倒计时") 
                    startNewTimer()
                }
            }
        }
        .onReceive(timer) { _ in
             for i in runningTimers.indices {
                 if runningTimers[i].remainingTime > 0 {
                     runningTimers[i].remainingTime -= 1
                 } else {
                     runningTimers[i].isFinished = true
                     
                     // Trigger Notification ONCE
                     if !runningTimers[i].hasNotified {
                         runningTimers[i].hasNotified = true
                         
                         // Record Last Finished
                         lastRecordMinutes = Int(runningTimers[i].totalTime / 60)
                         let recordTitle = runningTimers[i].title.trimmingCharacters(in: .whitespacesAndNewlines)
                         lastRecordTitle = recordTitle.isEmpty ? l10n.t("流光倒计时") : recordTitle
                         
                         let timerId = runningTimers[i].id
                         let title = runningTimers[i].title
                         
                         // Play Sound if enabled
                         if enableSound {
                             NSSound(named: "Glass")?.play()
                         }
                         
                         // Route to System Notification
                         if useSystemNotification {
                             NotificationManager.shared.sendNotification(
                                 title: title.isEmpty ? l10n.t("倒计时结束") : title,
                                 subtitle: l10n.t("时间到！")
                             )
                         }
                         
                         // Route to Floating Island (custom banner)
                         if useFloatingIsland {
                             NotificationWindowManager.shared.show(
                                 title: title,
                                 onSnooze: { min in
                                     self.snoozeTimer(id: timerId, minutes: min)
                                 },
                                 onDismiss: {
                                     self.dismissTimer(id: timerId)
                                 }
                             )
                         }
                     }
                 }
             }
        }
    }
    
    // MARK: - Actions
    
    func startNewTimer() {
        let newTimer = RunningTimer(
            totalTime: TimeInterval(minutes * 60),
            remainingTime: TimeInterval(minutes * 60),
            title: timerTitle
        )
        
        // Collapse sequence
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showPresets = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                runningTimers.append(newTimer)
                appState = .idle
                minutes = 0
                timerTitle = ""
                isDragging = false 
            }
        }
    }
    
    func stopTimer(_ timer: RunningTimer) {
        withAnimation {
            runningTimers.removeAll { $0.id == timer.id }
        }
    }
    
    func snoozeTimer(id: UUID, minutes: Int) {
        if let index = runningTimers.firstIndex(where: { $0.id == id }) {
            withAnimation {
                let addedTime = TimeInterval(minutes * 60)
                runningTimers[index].remainingTime = addedTime
                runningTimers[index].totalTime = addedTime // Reset total visual ring
                runningTimers[index].isFinished = false
                runningTimers[index].hasNotified = false // Reset notification trigger
            }
        }
    }
    
    func dismissTimer(id: UUID) {
        withAnimation {
            runningTimers.removeAll { $0.id == id }
        }
    }
    
    func reset() {
        withAnimation {
            showPresets = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                appState = .idle
            }
        }
    }
    
    func togglePreset() {
        guard minutes > 0 else { return }
        let effectiveTitle = timerTitle.isEmpty ? l10n.t("自定义") : timerTitle
        
        if let index = savedPresets.firstIndex(where: { $0.minutes == minutes && $0.title == effectiveTitle }) {
            // Un-favorite: Remove matching preset
            withAnimation {
                _ = self.savedPresets.remove(at: index)
            }
        } else {
            // Favorite: Add new preset
            let newPreset = TimerPreset(minutes: minutes, title: effectiveTitle)
            withAnimation {
                savedPresets.append(newPreset)
            }
        }
    }
    
    func deletePreset(_ preset: TimerPreset) {
        withAnimation {
            savedPresets.removeAll { $0.id == preset.id }
        }
    }
    
    /// Switch layout mode with "absorb and release" animation
    func switchLayoutMode(to newMode: LayoutMode) {
        guard newMode != layoutMode else { return }
        
        // Phase 1: Hide current timers sequentially (reuse remove transition)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isHidingForSwitch = true
        }
        
        // Phase 2: Switch layout mode after hide animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.layoutMode = newMode
            
            // Phase 3: Show new timers (reuse add transition)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    self.isHidingForSwitch = false
                }
            }
        }
    }

    private func updateWindowLevel() {
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.level == .floating || $0.level == .normal }) {
            window.level = isAlwaysOnTop ? .floating : .normal
        }
    }
}

// MARK: - Components Helper

struct RunningTimerView: View {
    @Binding var timer: RunningTimer
    @Binding var hoverLockout: Bool
    var layoutMode: LayoutMode = .horizontal
    var onStop: () -> Void
    
    @State private var isHovering = false
    @State private var isClosing = false // Two-stage closing flag
    
    private let l10n = LocalizationManager.shared
    
    // Helper to format time "MM:ss"
    private var formattedTime: String {
        let m = Int(timer.remainingTime) / 60
        let s = Int(timer.remainingTime) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    // Determine alignment based on layout mode
    // Horizontal: expand to the left (align trailing, content grows left)
    // Vertical: expand to the right (align leading, content grows right)
    private var zStackAlignment: Alignment {
        layoutMode == .horizontal ? .trailing : .leading
    }
    
    // Transition edge for expanded content
    private var expandTransitionEdge: Edge {
        layoutMode == .horizontal ? .trailing : .leading
    }
    
    var body: some View {
        ZStack(alignment: zStackAlignment) {
            // Morphing logic
            let effectiveHover = isHovering && !isClosing
            
            // Background Squircle
            if effectiveHover {
                RoundedRectangle(cornerRadius: 50 * 0.42, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 50 * 0.42, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .matchedGeometryEffect(id: "bg", in: namespace)
            }

            HStack(spacing: 8) {
                // For vertical layout, circle is on the left, content expands to the right
                // For horizontal layout, content is on the left, circle is on the right
                
                if layoutMode == .horizontal {
                    // HORIZONTAL: Ball on LEFT, content expands to RIGHT, close button on far RIGHT
                    // [Ball] [Time+Title] [X]
                    
                    // 1. Left Icon: Badge (Hover) OR Progress Ring (Normal)
                    ZStack {
                        if effectiveHover {
                            ZStack {
                                RoundedRectangle(cornerRadius: 42 * 0.42, style: .continuous)
                                    .fill(Color.white.opacity(0.2)) 
                                
                                let mins = Int(timer.totalTime / 60)
                                Text("\(mins)")
                                    .font(.system(size: mins > 99 ? 13 : 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 42, height: 42) 
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            TimerCircleView(totalTime: timer.totalTime, remainingTime: timer.remainingTime)
                                .transition(.identity)
                        }
                    }
                    
                    // 2. Expanded Info (Visible on Hover) - expands to the RIGHT
                    if effectiveHover {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(formattedTime)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            MarqueeText(
                                text: timer.title.isEmpty ? l10n.t("倒计时") : timer.title,
                                font: .system(size: 13, weight: .medium),
                                leftFade: 0,
                                rightFade: 5,
                                startDelay: 0.5,
                                alignment: .leading,
                                isHovering: effectiveHover
                            )
                            .frame(width: 96, height: 16)
                            .opacity(0.8)
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                        // Close Button (rightmost)
                        Button(action: {
                            performClose()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 24, height: 24)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                } else {
                    // VERTICAL: Circle on left, content expands to the right
                    // 1. Left Icon: Badge (Hover) OR Progress Ring (Normal)
                    ZStack {
                        if effectiveHover {
                            ZStack {
                                RoundedRectangle(cornerRadius: 42 * 0.42, style: .continuous)
                                    .fill(Color.white.opacity(0.2)) 
                                
                                let mins = Int(timer.totalTime / 60)
                                Text("\(mins)")
                                    .font(.system(size: mins > 99 ? 13 : 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 42, height: 42) 
                            .transition(.scale.combined(with: .opacity))
                        } else {
                            TimerCircleView(totalTime: timer.totalTime, remainingTime: timer.remainingTime)
                                .transition(.identity)
                        }
                    }
                    
                    // 2. Expanded Info (Visible on Hover)
                    if effectiveHover {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(formattedTime)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            
                            MarqueeText(
                                text: timer.title.isEmpty ? l10n.t("倒计时") : timer.title,
                                font: .system(size: 13, weight: .medium),
                                leftFade: 0,
                                rightFade: 5,
                                startDelay: 0.5,
                                alignment: .leading,
                                isHovering: effectiveHover
                            )
                            .frame(width: 96, height: 16)
                            .opacity(0.8)
                        }
                        .transition(.scale(scale: 0.9, anchor: .leading).combined(with: .opacity))
                        
                        // Close Button (rightmost in vertical)
                        Button(action: {
                            performClose()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 24, height: 24)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 4)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.leading, effectiveHover ? 4 : 0)
            .padding(.trailing, effectiveHover ? 8 : 0)
        }
        .frame(height: 50) 
        .fixedSize(horizontal: true, vertical: false) 
        .onHover { hover in
            if !hoverLockout && !isClosing {
                // Softened morphing (Response 0.4)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isHovering = hover
                }
            }
        }
        .padding(.vertical, 0)
    }
    
    private func performClose() {
        // START CLOSING SEQUENCE
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isClosing = true      // Morph back into circle
            hoverLockout = true  // Lock other timers' hover
        }
        
        // Wait for morph back animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onStop() // Trigger parent removal
            
            // Re-enable hover after removal is likely done
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hoverLockout = false
            }
        }
    }
    
    @Namespace private var namespace
}

