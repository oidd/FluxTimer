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
            // FIX: Use a continuous rounded rect path matching the mask (cornerRadius 42 for height 100), 
            // and inset by 2px to prevent the 4px stroke from being clipped at the edges.
            // Note: cornerRadius ratio is 0.42 to match NotificationBannerView's mask.
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            let capsulePath = Path(roundedRect: rect, cornerRadius: size.height * 0.42, style: .continuous)
            
            // 1. CALCULATE POSITIONS (Head, Mid, Tail and intermediate points for smooth reveal)
            let startP = (sweepProgress - streamerLength + 1.0).truncatingRemainder(dividingBy: 1.0)
            let endP = sweepProgress
            
            // Sample 5 points along the streamer for a broader reveal zone
            var lightingPoints: [CGPoint] = []
            for i in 0...4 {
                let p = (startP + (streamerLength * CGFloat(i) / 4.0)).truncatingRemainder(dividingBy: 1.0)
                // Use the path itself to find the point (Perfect accuracy for any shape)
                // Using a non-zero end ensures we get a valid point even at p=0
                let checkP = max(0.0001, p)
                if let pt = capsulePath.trimmedPath(from: 0, to: checkP).currentPoint {
                    lightingPoints.append(pt)
                } else {
                    // Fallback (should rarely happen)
                    lightingPoints.append(CGPoint(x: rect.midX, y: rect.minY)) 
                }
            }
            
            // 2. DRAW VISIBLE STREAMER (Segmented for perfect curve following)
            context.drawLayer { layer in
                let stepSize: CGFloat = 0.002 // Finer steps for smoother gradient
                let totalSteps = Int(streamerLength / stepSize)
                
                for i in 0..<totalSteps {
                    let relativePos = CGFloat(i) / CGFloat(totalSteps) // 0.0 to 1.0 along streamer
                    // Gaussian-like opacity curve: 0 -> 1 -> 0
                    // Peak at 0.5. 
                    // Use sine for smooth bell shape: sin(0 to PI)
                    let opacity = sin(relativePos * .pi) 
                    
                    let pStart = (startP + CGFloat(i) * stepSize).truncatingRemainder(dividingBy: 1.0)
                    let pEnd = (pStart + stepSize).truncatingRemainder(dividingBy: 1.0)
                    
                    // Handle wrapping logic for segments
                    let segmentPath: Path
                    if pStart < pEnd {
                        segmentPath = capsulePath.trimmedPath(from: pStart, to: pEnd)
                    } else {
                         // Edge case: tiny segment wraps around 1.0 -> 0.0
                         var p = capsulePath.trimmedPath(from: pStart, to: 1.0)
                         p.addPath(capsulePath.trimmedPath(from: 0.0, to: pEnd))
                         segmentPath = p
                    }
                    
                    // Main Glow
                    layer.stroke(segmentPath, with: .color(.white.opacity(opacity * 0.9)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    
                    // Core Brightness
                    layer.stroke(segmentPath, with: .color(.white.opacity(opacity)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
                
                // Add a global blur to smooth out the segments
                layer.addFilter(.blur(radius: 2.0))
            }
            
            // 3. DRAW STARS (Reveal near any part of the streamer)
            // Weighting mirrors the streamer's gradient: Middle is strongest, tails are weak.
            let weighting: [CGFloat] = [0.15, 0.65, 1.0, 0.65, 0.15]
            
            for star in stars {
                let starPos = CGPoint(x: star.x * size.width, y: star.y * size.height)
                
                var maxLocalEffect: CGFloat = 0
                for i in 0...4 {
                    // Safe guard index access although loops match
                    if i < lightingPoints.count {
                        let pt = lightingPoints[i]
                        let d = sqrt(pow(starPos.x - pt.x, 2) + pow(starPos.y - pt.y, 2))
                        
                        // Falloff for the "energy" of this specific point
                        let localEffect = pow(max(0, 1.0 - (d / 90)), 2.2) * weighting[i]
                        if localEffect > maxLocalEffect { maxLocalEffect = localEffect }
                    }
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
}
