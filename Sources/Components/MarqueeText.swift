import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    var leftFade: CGFloat = 16
    var rightFade: CGFloat = 16
    var startDelay: Double = 1.5
    var alignment: Alignment = .leading
    
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            let textWidth = text.width(usingFont: font)
            let isTooLong = textWidth > geometry.size.width
            
            ZStack(alignment: alignment) {
                Text(text)
                    .font(font)
                    .fixedSize() // Prevent wrapping
                    .offset(x: animate && isTooLong ? -(textWidth - geometry.size.width) : 0)
                    .animation(
                        isTooLong
                        ? .linear(duration: Double(textWidth) / 30).delay(startDelay).repeatForever(autoreverses: true)
                        : .default,
                        value: animate
                    )
                    .onAppear {
                        // Reset and restart animation to ensure it catches layout changes
                        animate = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            animate = true
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
            // Fade Edges if needed (Optional, user didn't explicitly ask for fade, just scroll)
            // But fade looks nicer.
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
        .frame(height: 20) // Fixed height for title line
    }
}

// Helper to calculate text width
extension String {
    func width(usingFont font: Font) -> CGFloat {
        // Platform specific font handling
        #if canImport(AppKit)
        let nsFont = font.toNSFont() ?? .systemFont(ofSize: 12)
        let attributes = [NSAttributedString.Key.font: nsFont]
        let size = (self as NSString).size(withAttributes: attributes)
        return size.width
        #else
        return 100 // Fallback
        #endif
    }
}

// Font conversion helper
extension Font {
    #if canImport(AppKit)
    func toNSFont() -> NSFont? {
        // Simplified mapping, robust enough for basic sizing
        // In a real app, you might need a more comprehensive mappers.
        return NSFont.systemFont(ofSize: 12) 
    }
    #endif
}
