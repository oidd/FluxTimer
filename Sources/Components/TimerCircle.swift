import SwiftUI

struct TimerCircleView: View {
    var totalTime: TimeInterval
    var remainingTime: TimeInterval
    
    var body: some View {
        ZStack {
            // Background Blur
            Circle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
            
            if remainingTime > 60 {
                // Minute Mode: Solid Ring
                // Progress moves counter-clockwise or clockwise? Usually clockwise reduces.
                // "实线白线逐渐变短"
                let progress = remainingTime / max(totalTime, 1.0)
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: remainingTime) // Smooth updates
                
                // Text
                Text("\(Int(ceil(remainingTime / 60.0)))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
            } else {
                // Second Mode: Dashed Ring (12 ticks)
                // "12个刻度的虚线... 慢慢地跟着减少"
                // 60 seconds -> 12 ticks. Each tick = 5 seconds.
                let tickCount = 12
                let activeTicks = Double(tickCount) * (remainingTime / 60.0)
                
                ForEach(0..<tickCount, id: \.self) { index in
                    // Only show ticks that are "active"
                    if Double(index) < activeTicks {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 6)
                            .offset(y: -22) // Radius approx
                            .rotationEffect(.degrees(Double(index) * (360.0 / Double(tickCount))))
                    }
                }
                .rotationEffect(.degrees(-90)) // Start at top
                
                // Text
                Text("\(Int(remainingTime))")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: remainingTime))
                    .animation(.snappy, value: remainingTime)
            }
        }
        .frame(width: 60, height: 60)
    }
}
