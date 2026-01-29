import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    var leftFade: CGFloat = 16
    var rightFade: CGFloat = 16
    var startDelay: Double = 1.5
    var alignment: Alignment = .leading
    var isHovering: Bool = true // Control scrolling externally
    
    @State private var animate = false
    @State private var contentWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let isTooLong = contentWidth > geometry.size.width + 2 // Add tiny tolerance
            let shouldScroll = isTooLong && isHovering
            let scrollDistance = contentWidth - geometry.size.width
            // Calculate duration based on speed (pixels per second), e.g., 30px/sec
            let duration = Double(contentWidth) / 60.0
            
            ZStack(alignment: alignment) {
                Text(text)
                    .font(font)
                    .fixedSize() // Prevent wrapping
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear { contentWidth = textGeo.size.width }
                                .onChange(of: text) { _ in contentWidth = textGeo.size.width }
                        }
                    )
                    .offset(x: animate && shouldScroll ? -scrollDistance : 0)
                    .animation(
                        shouldScroll
                        ? .easeInOut(duration: duration).delay(startDelay).repeatForever(autoreverses: true)
                        : .default,
                        value: animate
                    )
                    .onAppear {
                        // Reset and restart animation to ensure it catches layout changes
                        animate = false
                        if isHovering {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                animate = true
                            }
                        }
                    }
                    .onChange(of: isHovering) { hovering in
                        animate = false
                        if hovering {
                            // Wait for the expansion animation to finish before starting marquee
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                animate = true
                            }
                        }
                    }
                    .onChange(of: text) { _ in
                        animate = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            animate = true
                        }
                    }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignment)
            .clipped()
            .mask(
                HStack(spacing: 0) {
                    if isTooLong {
                        LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: leftFade)
                    }
                    Rectangle().fill(Color.black)
                    if isTooLong {
                        LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: rightFade)
                    }
                }
            )
        }
    }
}
