import SwiftUI

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
    
    @State private var savedPresets: [TimerPreset] = [
        TimerPreset(minutes: 1, title: "1m 测试"),
        TimerPreset(minutes: 5, title: "休息一下"),
        TimerPreset(minutes: 25, title: "番茄专注"),
        TimerPreset(minutes: 3, title: "泡面")
    ]
    
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
            
            // 1. LEFT WING (Timers)
            // Ends at x = 363 (375 - 12)
            HStack(spacing: 12) {
                Spacer() // Fill from left
                ForEach($runningTimers) { $timer in
                    RunningTimerView(timer: $timer, hoverLockout: $hoverLockout, onStop: {
                         stopTimer(timer)
                    })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.trailing, 62) // Maintain 12px gap from button during running
            .frame(width: 525, height: 80, alignment: .trailing) 
            .offset(x: 0, y: 35) 
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
                                    }
                                }
                            }
                        }
                    }) {
                        Color.clear.contentShape(Circle())
                    }
                }
                .frame(width: 50, height: 50)
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
            .offset(x: 475, y: 50)
            .zIndex(100) // Always on Top
            
            // 3. RIGHT WING (Capsule)
            // Starts at x = 437 (425 + 12)
            ZStack(alignment: .topLeading) {
                if appState == .setting || isDragging {
                    VStack(alignment: .leading, spacing: 5) {
                        DragCapsuleView(
                            minutes: $minutes,
                            isDragging: $isDragging,
                            title: $timerTitle,
                            isFavorite: savedPresets.contains { $0.minutes == minutes && $0.title == (timerTitle.isEmpty ? "自定义" : timerTitle) },
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
                            onSelect: { preset in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    self.minutes = preset.minutes
                                    self.timerTitle = preset.title
                                    startNewTimer()
                                }
                            },
                            onDelete: { preset in
                                deletePreset(preset)
                            }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .offset(x: 537, y: 50)
            .zIndex(50) // Behind button, in front of background
        }
        .frame(width: 1000, height: 600, alignment: .topLeading)
        .onReceive(timer) { _ in
             for i in runningTimers.indices {
                 if runningTimers[i].remainingTime > 0 {
                     runningTimers[i].remainingTime -= 1
                 } else {
                     runningTimers[i].isFinished = true
                     
                     // Trigger Notification ONCE
                     if !runningTimers[i].hasNotified {
                         runningTimers[i].hasNotified = true
                         let timerId = runningTimers[i].id
                         let title = runningTimers[i].title
                         
                         print("DEBUG: Showing notification for \(title)") // Debug
                         
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
        let effectiveTitle = timerTitle.isEmpty ? "自定义" : timerTitle
        
        if let index = savedPresets.firstIndex(where: { $0.minutes == minutes && $0.title == effectiveTitle }) {
            // Un-favorite: Remove matching preset
            withAnimation {
                savedPresets.remove(at: index)
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
}

// MARK: - Components Helper

struct RunningTimerView: View {
    @Binding var timer: RunningTimer
    @Binding var hoverLockout: Bool
    var onStop: () -> Void
    
    @State private var isHovering = false
    @State private var isClosing = false // Two-stage closing flag
    
    // Helper to format time "MM:ss"
    private var formattedTime: String {
        let m = Int(timer.remainingTime) / 60
        let s = Int(timer.remainingTime) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Morphing logic
            let effectiveHover = isHovering && !isClosing
            
            // Background Capsule
            if effectiveHover {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                    .matchedGeometryEffect(id: "bg", in: namespace)
            }

            HStack(spacing: 8) {
                // 1. Left Icon: Badge (Hover) OR Progress Ring (Normal)
                ZStack {
                    if effectiveHover {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2)) 
                            
                            Text("\(Int(timer.totalTime / 60))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
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
                            text: timer.title.isEmpty ? "倒计时" : timer.title,
                            font: .system(size: 13, weight: .medium),
                            leftFade: 5,
                            rightFade: 5,
                            startDelay: 0.5,
                            alignment: .leading
                        )
                        .frame(width: 80, height: 16)
                        .opacity(0.8)
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    
                    // Close Button
                    Button(action: {
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
            .padding(.horizontal, effectiveHover ? 8 : 0)
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
    
    @Namespace private var namespace
}

