import SwiftUI

struct BookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let notchH = h * 0.22
        
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w/2, y: h - notchH))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()
        return path
    }
}

struct BookmarkParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let delay: Double
}

struct BookmarkButton: View {
    let isFavorite: Bool
    var onToggle: () -> Void
    
    @State private var particles: [BookmarkParticle] = []
    @State private var showBurst = false
    @State private var particleOpacity: Double = 0
    @State private var burstScale: CGFloat = 0
    @State private var burstOpacity: Double = 0
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    
    var body: some View {
        ZStack {
            // The Custom Bookmark Shape (Stroke)
            BookmarkShape()
                .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .foregroundColor(.white.opacity(isFavorite ? 0.9 : 0.4))
                .frame(width: 11, height: 14)
                .scaleEffect(iconScale)
                .rotationEffect(.degrees(iconRotation))
            
            if isFavorite {
                BookmarkShape()
                    .fill(.white.opacity(0.7))
                    .frame(width: 11, height: 14)
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
            }
            
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(.white)
                    .frame(width: 5, height: 5)
                    .blur(radius: 0.5)
                    .offset(x: showBurst ? particle.x : 0, y: showBurst ? particle.y : 0)
                    .scaleEffect(showBurst ? particle.scale : 0.01)
                    .opacity(particleOpacity)
            }
            
            // Flash
            Circle()
                .fill(RadialGradient(colors: [.white.opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 32, height: 32)
                .scaleEffect(burstScale)
                .opacity(burstOpacity)
                
            // Interaction Layer
            Color.white.opacity(0.001)
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isFavorite { triggerBurst() }
                    onToggle()
                }
        }
        .frame(width: 20, height: 20)
    }
    
    private func triggerBurst() {
        showBurst = false
        burstScale = 0
        burstOpacity = 0
        particles = []
        
        iconRotation = -15
        iconScale = 0.85
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconRotation = 0
            iconScale = 1.2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { iconScale = 1.1 }
        }
        
        var newParticles: [BookmarkParticle] = []
        for i in 0..<6 {
            let angle = (CGFloat(i) / 6.0) * (2.0 * .pi)
            let radius = 24.0 + CGFloat.random(in: 0...10)
            newParticles.append(BookmarkParticle(x: cos(angle) * radius, y: sin(angle) * radius * 0.75, scale: 0.8 + CGFloat.random(in: 0...0.5), delay: Double(i) * 0.04))
        }
        self.particles = newParticles
        
        withAnimation(.easeOut(duration: 0.5)) {
            burstScale = 1.4
            burstOpacity = 0.4
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.2)) { burstOpacity = 0 }
        
        particleOpacity = 1.0
        withAnimation(.easeOut(duration: 0.8)) {
            showBurst = true
            particleOpacity = 0
        }
    }
}
