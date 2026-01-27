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
            .frame(width: 363, height: 50) // Explicit width ending at 363
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
    
    var body: some View {
        ZStack {
             TimerCircleView(totalTime: timer.totalTime, remainingTime: timer.remainingTime)
                 .onTapGesture {
                     onStop()
                 }
        }
        .frame(width: 50, height: 50)
    }
}

