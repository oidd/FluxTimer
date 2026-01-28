import SwiftUI

struct NotificationBannerView: View {
    let title: String
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void 
    
    // Animation States
    @State private var isExpanded = false
    @State private var contentOpacity: Double = 0
    @State private var dotStates: [Bool] = [false, false, false]
    
    // Safety flag for race conditions (snooze vs auto-dismiss)
    @State private var isDismissing = false
    
    // Auto-dismiss state
    @State private var timeRemaining: CGFloat = 30 
    @State private var totalTime: CGFloat = 30
    @State private var rotation: Double = 0 // For the masked rotating glow
    
    // Snooze Options
    @AppStorage("snoozeOption1") private var snoozeOption1: Int = 1
    @AppStorage("snoozeOption2") private var snoozeOption2: Int = 5
    @AppStorage("snoozeOption3") private var snoozeOption3: Int = 30
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Action to start the reverse morphing
    func startDismissSequence() {
        guard !isDismissing else { return }
        isDismissing = true
        
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                dotStates = [false, false, false]
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 1. Background Layer (Back)
            ZStack {
                // Main Material
                RoundedRectangle(cornerRadius: 100 * 0.42, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // GALACTIC STARFIELD SWEEP
                if isExpanded && contentOpacity > 0.5 {
                    TimelineView(.animation) { timeline in
                        let date = timeline.date.timeIntervalSinceReferenceDate
                        let progress = (date.remainder(dividingBy: 6.0) + 3.0) / 6.0 
                        StarfieldView(width: 780, height: 100, sweepProgress: progress)
                    }
                    .mask(RoundedRectangle(cornerRadius: 100 * 0.42, style: .continuous).fill(.white))
                }
                
                // Static Subtle Border
                RoundedRectangle(cornerRadius: 100 * 0.42, style: .continuous)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 1)
            }
            .frame(width: isExpanded ? 780 : 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 100 * 0.42, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10) 
            
            // 2. Content Layer (Front)
            HStack(spacing: 0) {
                if isExpanded {
                    // LEFT: Close
                    Button(action: startDismissSequence) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 3)
                            Circle()
                                .trim(from: 0, to: timeRemaining / totalTime)
                                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Image(systemName: "xmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.plain)
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
                    .padding(.leading, 40)
                    .opacity(contentOpacity)
                    
                    // MIDDLE: Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizationManager.shared.t("时间到"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(title.isEmpty ? LocalizationManager.shared.t("倒计时结束") : title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 24)
                    .frame(maxWidth: 350, alignment: .leading)
                    .opacity(contentOpacity)
                    .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity), removal: .opacity))
                    
                    Spacer()
                }
                
                // RIGHT: Three Dots / Snooze Buttons
                HStack(spacing: isExpanded ? 16 : 8) {
                    MorphedSnoozeButton(label: "+\(snoozeOption1) min", isActive: dotStates[0], isExpanded: isExpanded) {
                        if !isDismissing {
                            isDismissing = true
                            onSnooze(snoozeOption1)
                        }
                    }
                    MorphedSnoozeButton(label: "+\(snoozeOption2) min", isActive: dotStates[1], isExpanded: isExpanded) {
                        if !isDismissing {
                            isDismissing = true
                            onSnooze(snoozeOption2)
                        }
                    }
                    MorphedSnoozeButton(label: "+\(snoozeOption3) min", isActive: dotStates[2], isExpanded: isExpanded) {
                        if !isDismissing {
                            isDismissing = true
                            onSnooze(snoozeOption3)
                        }
                    }
                }
                .padding(.trailing, isExpanded ? 40 : 0)
                .frame(width: isExpanded ? nil : 100) // Keep them centered when collapsed
            }
            .frame(width: isExpanded ? 780 : 100, height: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 25) // Breathing room for shadow at the top
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isExpanded = true
                }
                
                let delay = 0.2
                for i in 0..<3 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(i) * 0.1) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            dotStates[i] = true
                        }
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeIn(duration: 0.4)) {
                        contentOpacity = 1
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 0.1
            } else {
                startDismissSequence()
            }
        }
    }
}

struct MorphedSnoozeButton: View {
    let label: String
    let isActive: Bool      
    let isExpanded: Bool   
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Background Layer (Dot or Capsule)
                RoundedRectangle(cornerRadius: (isActive ? 44 : 12) * 0.42, style: .continuous)
                    .fill(isActive ? (isHovering ? Color.white.opacity(0.2) : Color.white.opacity(0.1)) : Color.white)
                    // CRITICAL: Set fixed height to prevent "Giant Capsule" bug
                    .frame(width: isActive ? nil : 12, height: isActive ? 44 : 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: (isActive ? 44 : 12) * 0.42, style: .continuous)
                            .strokeBorder(.white.opacity(isActive ? 0.1 : 0), lineWidth: 1)
                            .frame(height: isActive ? 44 : 12)
                    )
                
                // Content Layer
                if isActive {
                    Text(label)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(isHovering ? .white : .white.opacity(0.8))
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(height: 44) // Constant height for hit testing
            .scaleEffect(isActive ? 1.0 : (isExpanded ? 1.2 : 0.8))
        }
        .buttonStyle(.plain)
        .disabled(!isActive || !isExpanded)
        .onHover { hover in
            if isActive && isExpanded {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hover
                }
            }
        }
    }
}
