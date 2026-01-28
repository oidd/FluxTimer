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
            let capsulePath = getCapsulePath(in: CGRect(origin: .zero, size: size))
            
            // 1. CALCULATE POSITIONS (Head, Mid, Tail and intermediate points for smooth reveal)
            let startP = (sweepProgress - streamerLength + 1.0).truncatingRemainder(dividingBy: 1.0)
            let endP = sweepProgress
            
            // Sample 5 points along the streamer for a broader reveal zone
            var lightingPoints: [CGPoint] = []
            for i in 0...4 {
                let p = (startP + (streamerLength * CGFloat(i) / 4.0)).truncatingRemainder(dividingBy: 1.0)
                lightingPoints.append(getPerimeterPosition(for: p, in: size))
            }
            
            let startPos = lightingPoints.first!
            let endPos = lightingPoints.last!
            
            // 2. DRAW VISIBLE STREAMER (流光)
            context.drawLayer { layer in
                let streamerPath: Path
                if startP < endP {
                    streamerPath = capsulePath.trimmedPath(from: startP, to: endP)
                } else {
                    var p = capsulePath.trimmedPath(from: startP, to: 1.0)
                    p.addPath(capsulePath.trimmedPath(from: 0.0, to: endP))
                    streamerPath = p
                }
                
                let streamerGradient = Gradient(colors: [.clear, .white.opacity(0.8), .white, .white.opacity(0.8), .clear])
                
                layer.stroke(streamerPath, with: .linearGradient(
                    streamerGradient, startPoint: startPos, endPoint: endPos
                ), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                layer.addFilter(.blur(radius: 2.5))
                
                layer.stroke(streamerPath, with: .linearGradient(
                    streamerGradient, startPoint: startPos, endPoint: endPos
                ), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            }
            
            // 3. DRAW STARS (Reveal near any part of the streamer)
            // Weighting mirrors the streamer's gradient: Middle is strongest, tails are weak.
            let weighting: [CGFloat] = [0.15, 0.65, 1.0, 0.65, 0.15]
            
            for star in stars {
                let starPos = CGPoint(x: star.x * size.width, y: star.y * size.height)
                
                var maxLocalEffect: CGFloat = 0
                for i in 0...4 {
                    let pt = lightingPoints[i]
                    let d = sqrt(pow(starPos.x - pt.x, 2) + pow(starPos.y - pt.y, 2))
                    
                    // Falloff for the "energy" of this specific point
                    let localEffect = pow(max(0, 1.0 - (d / 90)), 2.2) * weighting[i]
                    if localEffect > maxLocalEffect { maxLocalEffect = localEffect }
                }
                
                // Base opacity (0.04) and flaring reveal
                let finalOpacity = max(star.baseOpacity * 0.04, star.baseOpacity * 11.0 * maxLocalEffect)
                
                if finalOpacity > 0.01 {
                    let rect = CGRect(
                        x: starPos.x - star.size/2,
                        y: starPos.y - star.size/2,
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
        let count = 200 
        
        for _ in 0..<count {
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)
            
            let dx = abs(x - 0.5) * 2.0
            let dy = abs(y - 0.5) * 2.0
            let distFromCenter = max(dx, dy) 
            
            let baseOpacity = pow(max(0, distFromCenter - 0.15), 1.6) * 0.8
            
            newStars.append(Star(
                x: x,
                y: y,
                size: CGFloat.random(in: 0.5...1.4),
                baseOpacity: baseOpacity
            ))
        }
        self.stars = newStars
    }
    
    // MARK: - Perimeter Logic
    
    private func getCapsulePath(in rect: CGRect) -> Path {
        let r = rect.height / 2
        var path = Path()
        // Top Left corner of the straight segment
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: rect.width - r, y: 0))
        path.addArc(center: CGPoint(x: rect.width - r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: r, y: rect.height))
        path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(90), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
    
    private func getPerimeterPosition(for progress: CGFloat, in size: CGSize) -> CGPoint {
        let r = size.height / 2
        let w = size.width
        let h = size.height
        let straightLen = w - h
        let curveLen = CGFloat.pi * r
        let totalPerimeter = 2 * straightLen + 2 * curveLen
        
        var current = progress.truncatingRemainder(dividingBy: 1.0) * totalPerimeter
        
        // Match the segments of getCapsulePath
        // 1. Top Straight
        if current <= straightLen {
            return CGPoint(x: r + current, y: 0)
        }
        current -= straightLen
        // 2. Right Arc
        if current <= curveLen {
            let angle = -CGFloat.pi/2 + (current / curveLen) * CGFloat.pi
            return CGPoint(x: (w-r) + cos(angle) * r, y: r + sin(angle) * r)
        }
        current -= curveLen
        // 3. Bottom Straight
        if current <= straightLen {
            return CGPoint(x: (w-r) - current, y: h)
        }
        current -= straightLen
        // 4. Left Arc
        let angle = CGFloat.pi/2 + (current / curveLen) * CGFloat.pi
        return CGPoint(x: r + cos(angle) * r, y: r + sin(angle) * r)
    }
}
