import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let baseOpacity: CGFloat
}

struct StarfieldView: View {
    let width: CGFloat
    let height: CGFloat
    
    @State private var stars: [Star] = []
    
    // We'll use a local timer if TimelineView is busy, 
    // but usually a parent will pass in a progress value.
    var sweepProgress: CGFloat // 0.0 to 1.0
    
    init(width: CGFloat, height: CGFloat, sweepProgress: CGFloat) {
        self.width = width
        self.height = height
        self.sweepProgress = sweepProgress
    }
    
    var body: some View {
        Canvas { context, size in
            let streamerLength: CGFloat = 0.22 
            let midP = (sweepProgress - streamerLength / 2 + 1.0).truncatingRemainder(dividingBy: 1.0)
            let midPos = getPerimeterPosition(for: midP, in: size)
            
            // 1. DRAW VISIBLE STREAMER (流光)
            let capsulePath = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: size.height / 2)
            
            context.drawLayer { layer in
                let startP = (sweepProgress - streamerLength + 1.0).truncatingRemainder(dividingBy: 1.0)
                let endP = sweepProgress
                
                let streamerPath: Path
                if startP < endP {
                    streamerPath = capsulePath.trimmedPath(from: startP, to: endP)
                } else {
                    var p = capsulePath.trimmedPath(from: startP, to: 1.0)
                    p.addPath(capsulePath.trimmedPath(from: 0.0, to: endP))
                    streamerPath = p
                }
                
                let streamerGradient = Gradient(colors: [.clear, .white.opacity(0.8), .white, .white.opacity(0.8), .clear])
                let startPos = getPerimeterPosition(for: startP, in: size)
                let endPos = getPerimeterPosition(for: endP, in: size)
                
                layer.stroke(streamerPath, with: .linearGradient(
                    streamerGradient, startPoint: startPos, endPoint: endPos
                ), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                layer.addFilter(.blur(radius: 2.5))
                
                layer.stroke(streamerPath, with: .linearGradient(
                    streamerGradient, startPoint: startPos, endPoint: endPos
                ), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
            
            // 2. DRAW STARS (More Subtle & Localized)
            for star in stars {
                let dx = star.x * size.width - midPos.x
                let dy = star.y * size.height - midPos.y
                let distToMid = sqrt(dx*dx + dy*dy)
                
                // Tightened falloff: concentrated near the streamer (85px radius)
                let lightEffect = pow(max(0, 1.0 - (distToMid / 85)), 2.5)
                
                // Reveal logic: Nearly invisible (0.04), flaring up gracefully (11.0)
                let finalOpacity = max(star.baseOpacity * 0.04, star.baseOpacity * 11.0 * lightEffect)
                
                if finalOpacity > 0.01 {
                    let rect = CGRect(
                        x: star.x * size.width - star.size/2,
                        y: star.y * size.height - star.size/2,
                        width: star.size,
                        height: star.size
                    )
                    
                    var resolvedStar = context
                    resolvedStar.opacity = finalOpacity
                    resolvedStar.fill(Circle().path(in: rect), with: .color(.white.opacity(0.95)))
                }
            }
        }
        .onAppear {
            generateStars()
        }
    }
    
    // MARK: - Star Generation
    
    private func generateStars() {
        var newStars: [Star] = []
        let count = 180 // Reduced density for clarity
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)
            
            let dx = abs(x - 0.5) * 2.0
            let dy = abs(y - 0.5) * 2.0
            let distFromCenter = max(dx, dy) 
            
            // Weighted opacity: Near nonexistent in center
            let baseOpacity = pow(max(0, distFromCenter - 0.2), 1.5) * 0.8
            
            newStars.append(Star(
                x: x,
                y: y,
                size: CGFloat.random(in: 0.5...1.5), // Smaller stars
                baseOpacity: baseOpacity
            ))
        }
        self.stars = newStars
    }
    
    // MARK: - Perimeter Path Logic
    
    private func getPerimeterPosition(for progress: CGFloat, in size: CGSize) -> CGPoint {
        // Create a Capsule path to sample from
        let rect = CGRect(origin: .zero, size: size)
        let path = Path(roundedRect: rect, cornerRadius: size.height / 2)
        
        // Use Trimmed Path to get a point at 'progress'
        // progress 0 is start (usually top middle or left side)
        let trimmed = path.trimmedPath(from: progress, to: min(1.0, progress + 0.001))
        return trimmed.currentPoint ?? CGPoint(x: size.width/2, y: size.height/2)
    }
}
