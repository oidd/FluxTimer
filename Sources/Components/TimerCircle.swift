import SwiftUI

struct TimerCircleView: View {
    var totalTime: TimeInterval
    var remainingTime: TimeInterval
    
    // Animation States for "Retract & Reveal"
    @State private var isTransitioning = false
    @State private var retractProgress: CGFloat = 1.0 // 1 to 0: Line shrinks
    @State private var revealedIndices: Set<Int> = [] // Track CCW reveal sequence
    @State private var previousTime: TimeInterval?

    var body: some View {
        ZStack {
            // Background Blur
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            
            if remainingTime > 60 || (isTransitioning && retractProgress > 0) {
                // Minute Mode: Solid Ring
                // Default receding from end-point toward Start (-90 deg) is CCW.
                let progress = remainingTime / max(totalTime, 1.0)
                
                Circle()
                    .trim(from: 0, to: isTransitioning ? retractProgress * CGFloat(progress) : CGFloat(progress))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: remainingTime)
                
                if !isTransitioning {
                    let mins = Int(ceil(remainingTime / 60.0))
                    Text("\(mins)")
                        .font(.system(size: mins > 99 ? 17 : 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
            
            if (remainingTime <= 60 && !isTransitioning) || (isTransitioning && !revealedIndices.isEmpty) {
                // Second Mode: Dashed Ring (12 ticks)
                let tickCount = 12
                let visibleTicksLimit = Int(ceil(remainingTime / 5.0))
                
                ForEach(0..<tickCount, id: \.self) { index in
                    let showRank = index + 1
                    
                    if showRank <= visibleTicksLimit && (isTransitioning ? revealedIndices.contains(index) : true) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 6)
                            .offset(y: -22)
                            .rotationEffect(.degrees(Double(index) * 30.0))
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                
                if !isTransitioning {
                if #available(macOS 14.0, *) {
                    Text("\(Int(remainingTime))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: remainingTime))
                        .animation(.snappy, value: remainingTime)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                } else {
                    Text("\(Int(remainingTime))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .animation(.snappy, value: remainingTime)
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
                }
            }
        }
        .frame(width: 50, height: 50)
        .onChange(of: remainingTime) { newValue in
            // Use local state to simulate oldValue for precise boundary detection
            let oldVal = previousTime ?? newValue
            previousTime = newValue
            
            // Trigger "Retract & Reveal" transition ONLY when crossing 60s (from >60 to <=60)
            if oldVal > 60 && newValue <= 60 && !isTransitioning {
                isTransitioning = true
                retractProgress = 1.0
                revealedIndices = []
                
                // 1. Phase: Retract CCW to Top (0.3s)
                withAnimation(.easeIn(duration: 0.3)) {
                    retractProgress = 0
                }
                
                // 2. Phase: Staggered Reveal CCW (0, 11, 10, 9... 1)
                // Start after retract finishes
                let startDelay = 0.3
                for i in 0..<12 {
                    let dotIdx = (12 - i) % 12
                    DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + Double(i) * 0.05) {
                        if self.isTransitioning {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                self.revealedIndices.insert(dotIdx)
                            }
                        }
                    }
                }
                
                // 3. Phase: Finalize
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + 0.6 + 0.2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTransitioning = false
                    }
                }
            }
        }
    }
}
