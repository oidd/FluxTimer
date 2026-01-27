import SwiftUI

struct ContentView: View {
    enum AppState {
        case idle // Plus button only
        case setting // Expanded capsule
        case running // Countdown active
        case finished // Ripple effect
    }
    
    @State private var appState: AppState = .idle
    @State private var minutes: Int = 0
    @State private var timerTitle: String = ""
    @State private var isDragging = false
    @State private var isHovering = false
    @State private var remainingTime: TimeInterval = 0
    @State private var totalTime: TimeInterval = 0
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
        VStack(alignment: .leading, spacing: 0) {
            // Main Timer Area (Top Row)
            HStack(spacing: 5) { // Positive spacing to separate Circle and Capsule
                ZStack {
                    if appState == .running || appState == .finished {
                        TimerCircleView(totalTime: totalTime, remainingTime: remainingTime)
                            .transition(.scale.combined(with: .opacity))
                            .onTapGesture {
                                reset()
                            }
                    } else {
                        ClickDraggableButton(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                if appState == .idle {
                                    appState = .setting
                                    minutes = 0 // Reset
                                } else {
                                    appState = .idle
                                }
                            }
                        }) {
                            PlusButton(isExpanded: appState == .setting || isDragging) {}
                        }
                        .frame(width: 50, height: 50)
                        .contentShape(Circle()) // STRICT HOVER SHAPE (Only the circle)
                        .onHover { hover in
                            if hover {
                                cancelHoverClose()
                            } else {
                                scheduleHoverClose()
                            }
                        }
                    }
                }
                .zIndex(20)
                
                // Capsule
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
                                startTimer()
                            }
                        },
                        onFavorite: {
                            savePreset()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity),
                        removal: .scale(scale: 0.1, anchor: .leading).combined(with: .opacity)
                    ))
                    .zIndex(10)
                }
            }
            .frame(height: 60)
            .zIndex(20)
            .padding(20)
            
            // Preset List
            // LOGIC: Conditional + Debounce + Zero Gap.
            // 1. Conditional: `if isHovering` removes it from hierarchy -> NO GHOST TRIGGER.
            // 2. Debounce: Allows mouse to travel from Button to List.
            // 3. Zero Gap: -35 padding pulls it up.
            
            if appState == .idle && isHovering {
                PresetListView(
                    isVisible: isHovering, // Always true here
                    presets: $savedPresets,
                    onSelect: { preset in
                        self.minutes = preset.minutes
                        self.timerTitle = preset.title
                        startTimer()
                    },
                    onDelete: { preset in
                        deletePreset(preset)
                    }
                )
                // Layout
                .padding(.top, -25)
                .padding(.leading, 28)
                // Bridge Logic: If checking here, cancel close
                .onHover { hover in
                    if hover {
                        cancelHoverClose()
                    } else {
                        scheduleHoverClose()
                    }
                }
                // Transitions: Fade ONLY.
                // Using .move can cause the view to slide under the mouse while closing, triggering a re-open loop ("Twitching").
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(timer) { _ in
            guard appState == .running else { return }
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                appState = .finished
            }
        }
    }
    
    func startTimer() {
        totalTime = TimeInterval(minutes * 60)
        remainingTime = totalTime
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            appState = .running
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
