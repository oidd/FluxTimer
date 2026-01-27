import SwiftUI

// MULTI-TIMER MODEL
struct RunningTimer: Identifiable, Equatable {
    let id = UUID()
    var totalTime: TimeInterval
    var remainingTime: TimeInterval
    var isFinished: Bool = false
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
    @State private var isHovering = false
    
    // MULTI-TIMER STATE
    @State private var runningTimers: [RunningTimer] = []
    
    @State private var savedPresets: [TimerPreset] = [
        TimerPreset(minutes: 5, title: "休息一下"),
        TimerPreset(minutes: 25, title: "番茄专注"),
        TimerPreset(minutes: 3, title: "泡面")
    ]
    
    // DEBOUNCE LOGIC
    @State private var hoverWorkItem: DispatchWorkItem?
    
    // Timer
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let dragLogic = DragLogic()
    
    // Helper for Debounce
    func scheduleHoverClose() {
        hoverWorkItem?.cancel()
        let item = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = false
            }
        }
        hoverWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: item)
    }
    
    func cancelHoverClose() {
        hoverWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            isHovering = true
        }
    }
    
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
                    RunningTimerView(timer: $timer, onStop: {
                         stopTimer(timer)
                    })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(width: 363, height: 50, alignment: .trailing) // Explicit width ending at 363, grow to LEFT
            .offset(x: 0, y: 20) // Top-Left origin
            .zIndex(10)
            
            // 2. CENTER ANCHOR (Button + Presets)
            // Starts at x = 375.
            VStack(alignment: .leading, spacing: 0) {
                // BUTTON
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    ZStack {
                        if appState == .idle {
                            PlusButton(isExpanded: isDragging) {}
                                .transition(.opacity.combined(with: .scale))
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    ClickDraggableButton(action: {
                        DispatchQueue.main.async {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if appState == .idle {
                                    appState = .setting
                                    minutes = 0
                                } else {
                                    appState = .idle
                                }
                            }
                        }
                    }) {
                        Color.clear.contentShape(Circle())
                    }
                }
                .frame(width: 50, height: 50)
                .onHover { hover in
                     if hover { cancelHoverClose() } else { scheduleHoverClose() }
                }
                
                // PRESET LIST (Connected below)
                if appState == .idle && isHovering {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 10)
                        .onHover { hover in
                            if hover { cancelHoverClose() } else { scheduleHoverClose() }
                        }
                    
                    PresetListView(
                        isVisible: isHovering, 
                        presets: $savedPresets,
                        onSelect: { preset in
                            self.minutes = preset.minutes
                            self.timerTitle = preset.title
                            startNewTimer()
                        },
                        onDelete: { preset in
                            deletePreset(preset)
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    .onHover { hover in
                        if hover { cancelHoverClose() } else { scheduleHoverClose() }
                    }
                }
            }
            .offset(x: 375, y: 20)
            .zIndex(100) // Topmost
            
            // 3. RIGHT WING (Capsule)
            // Starts at x = 437 (425 + 12)
            ZStack(alignment: .leading) {
                if appState == .setting || isDragging {
                    DragCapsuleView(
                        minutes: $minutes,
                        isDragging: $isDragging,
                        title: $timerTitle,
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
                        onFavorite: {
                            savePreset()
                        }
                    )
                    // Grow from Left (Button side)
                    .transition(.scale(scale: 0.1, anchor: .leading).combined(with: .opacity))
                }
            }
            .offset(x: 437, y: 20)
            .zIndex(10)
            
        }
        .frame(width: 800, height: 600, alignment: .topLeading)
        .onReceive(timer) { _ in
             for i in runningTimers.indices {
                 if runningTimers[i].remainingTime > 0 {
                     runningTimers[i].remainingTime -= 1
                 } else {
                     runningTimers[i].isFinished = true
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
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            runningTimers.append(newTimer)
            appState = .idle
            minutes = 0
            timerTitle = ""
            isDragging = false 
        }
    }
    
    func stopTimer(_ timer: RunningTimer) {
        withAnimation {
            runningTimers.removeAll { $0.id == timer.id }
        }
    }
    
    func reset() {
        withAnimation {
            appState = .idle
        }
    }
    
    func savePreset() {
        guard minutes > 0 else { return }
        let isDuplicate = savedPresets.contains { $0.minutes == minutes && $0.title == timerTitle }
        
        if !isDuplicate {
            let newPreset = TimerPreset(minutes: minutes, title: timerTitle.isEmpty ? "自定义" : timerTitle)
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
    var onStop: () -> Void
    
    @State private var isHovering = false
    
    // Helper to format time "MM:ss"
    private var formattedTime: String {
        let m = Int(timer.remainingTime) / 60
        let s = Int(timer.remainingTime) % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Capsule (Only visible when hovering)
            if isHovering {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .matchedGeometryEffect(id: "bg", in: namespace)
            } else {
                // Invisible placeholder to match height?
                // No, sticking to frame height 50 is enough.
            }

            HStack(spacing: 8) {
                // 1. Left Icon: Badge (Hover) OR Progress Ring (Normal)
                ZStack {
                    if isHovering {
                        // Static Badge (Total Minutes)
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2)) // Translucent background
                            
                            Text("\(Int(timer.totalTime / 60))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(width: 42, height: 42) // Matched scaled size
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Progress Ring
                        TimerCircleView(totalTime: timer.totalTime, remainingTime: timer.remainingTime)
                            .transition(.identity)
                    }
                }
                
                // 2. Expanded Info (Visible on Hover)
                if isHovering {
                    VStack(alignment: .leading, spacing: 0) {
                        // Digital Clock
                        Text(formattedTime)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        
                        // Title Marquee
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
                    Button(action: onStop) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 24, height: 24)
                            // Clean style: No background
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, isHovering ? 8 : 0) // Consistent horizontal padding
            // REMOVE VERTICAL PADDING: Lock to 50px height
        }
        .frame(height: 50) // Enforce 50px height
        .fixedSize(horizontal: true, vertical: false) // CRITICAL: Force ZStack to shrink-wrap content
        // Interaction
        .onHover { hover in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovering = hover
            }
        }
        // Click to toggle/stop? User said "Click close button to end".
        // Keep tap on circle as backup? Or remove?
        // Let's remove the tap on circle so user must use the X, preventing accidental closure.
        .padding(.vertical, 0) // Clean height
    }
    
    @Namespace private var namespace
}

