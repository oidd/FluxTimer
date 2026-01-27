import SwiftUI

struct TimerCircleView: View {
    var totalTime: TimeInterval
    var remainingTime: TimeInterval
    
    // Animation States
    @State private var isTransitioning = false
    @State private var sweepProgress: CGFloat = 0 // 0: Solid ring full, 1: Erased CCW to reveal ticks
    
    var body: some View {
        ZStack {
            // Background Blur
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            
            if remainingTime > 60 || isTransitioning {
                // Minute Mode: Solid Ring
                // Standard Circle path is clockwise. trim(0, to: progress) end-point moves CCW as progress decreases.
                let progress = remainingTime / max(totalTime, 1.0)
                
                Circle()
                    .trim(from: 0, to: isTransitioning ? 1.0 - sweepProgress : CGFloat(progress))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: remainingTime)
                
                if !isTransitioning {
                    Text("\(Int(ceil(remainingTime / 60.0)))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .transition(.opacity)
                }
            }
            
            if remainingTime <= 60 {
                // Second Mode: Dashed Ring (12 ticks)
                let tickCount = 12
                let visibleTicksLimit = Int(ceil(remainingTime / 5.0))
                
                ForEach(0..<tickCount, id: \.self) { index in
                    // Disappearance Priority (Visible Order):
                    // index 0 (12:00) -> Rank 1 (Last to go)
                    // index 1 (01:00) -> Rank 2
                    // ...
                    // index 11 (11:00) -> Rank 12 (First to go)
                    let rank = index + 1
                    
                    // Reveal Logic for micro-animation:
                    // Erase sweep starts at Top and moves CCW (11:00 -> 10:00 -> ...)
                    // 11:00 is at 1/12th of the CCW sweep.
                    let revealThreshold = (Double(360 - index * 30) / 360.0).truncatingRemainder(dividingBy: 1.0)
                    let isStepRevealed = isTransitioning ? (sweepProgress >= (revealThreshold == 0 ? 0 : 1.0 - revealThreshold)) : true
                    
                    if rank <= visibleTicksLimit && isStepRevealed {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 6)
                            .offset(y: -22)
                            .rotationEffect(.degrees(Double(index) * 30.0))
                            .transition(.opacity.combined(with: .scale(scale: 0.5)))
                    }
                }
                
                if !isTransitioning {
                    Text("\(Int(remainingTime))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: remainingTime))
                        .animation(.snappy, value: remainingTime)
                        .transition(.opacity)
                }
            }
        }
        .frame(width: 50, height: 50)
        .onChange(of: remainingTime) { oldValue, newValue in
            // Trigger Micro-Animation when CROSSING 60s
            if oldValue > 60 && newValue <= 60 {
                // Reset state
                sweepProgress = 0
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTransitioning = true
                }
                
                // Sweep reveal CCW (0 to 1 erases the line CCW from Top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        sweepProgress = 1.0
                    }
                }
                
                // Finish transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation {
                        isTransitioning = false
                    }
                }
            }
        }
    }
}
