import SwiftUI

struct NotificationBannerView: View {
    let title: String
    let onSnooze: (Int) -> Void
    let onDismiss: () -> Void 
    
    // Morph state
    @State private var isExpanded = false
    @State private var contentOpacity: Double = 0
    
    // Auto-dismiss state
    @State private var timeRemaining: CGFloat = 30 
    @State private var totalTime: CGFloat = 30
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    // Action to start the reverse morphing
    func startDismissSequence() {
        withAnimation(.easeOut(duration: 0.2)) {
            contentOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Shrink back
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded = false
            }
            
            // Wait for shrink and slide down
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onDismiss()
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Capsule
            Capsule()
                .fill(.ultraThinMaterial)
                .frame(width: isExpanded ? 780 : 100, height: 100)
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
            
            // MAIN CONTENT LAYER
            ZStack {
                // 1. LEFT: Close (Invisible in circle)
                HStack {
                    if isExpanded {
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
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // 2. MIDDLE: Info (Invisible in circle)
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("时间到")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text(title.isEmpty ? "倒计时结束" : title)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        .padding(.leading, 20)
                        .frame(maxWidth: 350, alignment: .leading)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    Spacer()
                    
                    // 3. RIGHT: Snooze Buttons (Morphed Dots)
                    HStack(spacing: isExpanded ? 16 : 8) {
                        SnoozeButton(label: "+1m", isExpanded: isExpanded, action: { onSnooze(1) })
                        SnoozeButton(label: "+5m", isExpanded: isExpanded, action: { onSnooze(5) })
                        SnoozeButton(label: "+30m", isExpanded: isExpanded, action: { onSnooze(30) })
                    }
                    .frame(width: isExpanded ? nil : 100) // Center dots in the 100px circle
                }
                .padding(.horizontal, isExpanded ? 40 : 0)
                .opacity(contentOpacity)
                
                // INITIAL DOTS (Overlayed when opacity is 0 or low)
                if !isExpanded || contentOpacity < 0.5 {
                    HStack(spacing: 8) {
                        Circle().fill(.white).frame(width: 10, height: 10)
                        Circle().fill(.white).frame(width: 10, height: 10)
                        Circle().fill(.white).frame(width: 10, height: 10)
                    }
                    .opacity(1.0 - contentOpacity)
                }
            }
            .frame(width: isExpanded ? 780 : 100, height: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isExpanded = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.3)) {
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

struct SnoozeButton: View {
    let label: String
    let isExpanded: Bool
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(isHovering ? .white : .white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isHovering ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                )
                .overlay(
                    Capsule().strokeBorder(.white.opacity(0.1), lineWidth: 1)
                )
                .scaleEffect(isExpanded ? 1.0 : 0.5)
                .opacity(isExpanded ? 1.0 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
    }
}
