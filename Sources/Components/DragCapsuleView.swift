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

struct DragCapsuleView: View {
    @Binding var minutes: Int
    @Binding var isDragging: Bool
    @Binding var title: String
    var isFavorite: Bool // Driven by ContentView
    var dragChanged: (CGFloat) -> Void
    var dragEnded: () -> Void
    var onCommit: () -> Void
    var onFavoriteToggle: () -> Void // Renamed to clarify toggle
    
    // Explicit init
    init(minutes: Binding<Int>, 
         isDragging: Binding<Bool>, 
         title: Binding<String>, 
         isFavorite: Bool,
         dragChanged: @escaping (CGFloat) -> Void, 
         dragEnded: @escaping () -> Void, 
         onCommit: @escaping () -> Void, 
         onFavoriteToggle: @escaping () -> Void) {
        self._minutes = minutes
        self._isDragging = isDragging
        self._title = title
        self.isFavorite = isFavorite
        self.dragChanged = dragChanged
        self.dragEnded = dragEnded
        self.onCommit = onCommit
        self.onFavoriteToggle = onFavoriteToggle
    }
    
    @State private var dragOffset: CGFloat = 0
    
    // PARTICLE & BURST STATE
    @State private var particles: [BookmarkParticle] = []
    @State private var showBurst = false
    @State private var particleOpacity: Double = 0
    @State private var burstScale: CGFloat = 0
    @State private var burstOpacity: Double = 0
    @State private var iconScale: CGFloat = 1.0
    @State private var iconRotation: Double = 0
    
    // SPACER MEMORY
    @State private var restingWidth: CGFloat = 0
    
    // VISUAL LIMIT
    private let visualLimit: CGFloat = 120
    
    var body: some View {
        HStack(spacing: 0) {
            // Time Display (Now includes Bookmark on the left)
            HStack(spacing: 8) {
                // Persistent Bookmark on Left
                ZStack {
                    // 1. BURST PARTICLES
                    ForEach(particles) { particle in
                        Circle()
                            .fill(.white)
                            .frame(width: 5, height: 5)
                            .blur(radius: 0.5)
                            .offset(x: showBurst ? particle.x : 0, y: showBurst ? particle.y : 0)
                            .scaleEffect(showBurst ? particle.scale : 0.01)
                            .opacity(particleOpacity)
                    }
                    
                    // 2. RADIAL GLOW FLASH
                    Circle()
                        .fill(RadialGradient(colors: [.white.opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: 15))
                        .frame(width: 32, height: 32)
                        .scaleEffect(burstScale)
                        .opacity(burstOpacity)
                    
                    // 3. ICON (Custom Shorter Bookmark)
                    ZStack {
                        BookmarkShape()
                            .stroke(style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 11, height: 14)
                        
                        BookmarkShape()
                            .fill(.white)
                            .frame(width: 11, height: 14)
                            .opacity(isFavorite ? 1 : 0)
                    }
                    .scaleEffect(iconScale)
                    .rotationEffect(.degrees(iconRotation))
                    .contentShape(Rectangle()) // Better hit area
                    .onTapGesture {
                        if minutes > 0 {
                            onFavoriteToggle()
                        }
                    }
                }
                .frame(width: 20, height: 20)
                
                Text("\(minutes) min")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .offset(y: -0.5) // Optical alignment
            }
            .padding(.horizontal, 14) // Tighter look
            .padding(.vertical, 10)   // Balanced vertical
            .background(Capsule().fill(.white.opacity(0.2)))
            .padding(.leading, 4)     // Shifted left
            .fixedSize()
            .onChange(of: isFavorite) { newValue in
                if newValue {
                    triggerBurst()
                }
            }
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
                .opacity(0.5)

            // Input Field
            TextField("提醒事项...", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding(.leading, 4) // Safety buffer to keep text away from divider
                .onSubmit {
                    onCommit()
                }
                .frame(width: 112) // Balanced for ~8 Chinese characters
            
            // DYNAMIC SPACER
            Spacer(minLength: 0)
                .frame(width: max(0, restingWidth + (isDragging ? dampedDelta(dragOffset) : 0)))
            
            // Morphing Handle (3 Bars <-> Plus)
            ZStack {
                // Hit Area
                Color.white.opacity(0.001) 
                    .frame(width: 30, height: 50)
                    .contentShape(Rectangle())
                
                let isPlus = minutes > 0 && !isDragging
                
                ZStack { // Use ZStack for perfect centering of Plus
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(width: 2, height: 12)
                            .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                            // MORPHING LOGIC:
                            // i=1: Stays centered, Always vertical.
                            // i=0: Moves to center and rotates 90 to form Horizontal.
                            // i=2: Fades out and moves to center.
                            .offset(x: isPlus ? 0 : CGFloat(i - 1) * 5)
                            .rotationEffect(.degrees(isPlus && i == 0 ? 90 : 0))
                            .opacity(isPlus && i == 2 ? 0 : 1)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isPlus)
            }
            .frame(width: 30)
            .padding(.trailing, 8)
            .onHover { hover in
                if hover {
                    NSCursor.openHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            // Tap for Commit (if plus)
            .onTapGesture {
                let isPlus = minutes > 0 && !isDragging
                if isPlus {
                    onCommit()
                }
            }
            // Drag to Edit
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                             NSCursor.closedHand.push()
                        }
                        isDragging = true 
                        dragOffset = value.translation.width
                        dragChanged(value.translation.width)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { 
                             dragOffset = 0
                        }
                        isDragging = false 
                        NSCursor.pop()
                        dragEnded()
                    }
            )
        }
        .frame(height: 50)
        .background(.ultraThinMaterial)
        .overlay(
            BoneCapsuleShape(dragOffset: isDragging ? dragOffset : 0)
                .stroke(.white.opacity(0.2), lineWidth: 2)
        )
        .clipShape(BoneCapsuleShape(dragOffset: isDragging ? dragOffset : 0))
        .fixedSize(horizontal: true, vertical: false)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .overlay(alignment: .topLeading) {
            if minutes > 0 {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
                    let timeString = endDate.formatted(date: .omitted, time: .standard)
                    
                    Text("预计 \(timeString) 结束计时")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .overlay(
                                    Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
                                )
                        )
                        .offset(y: -24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Burst Logic
    
    private func triggerBurst() {
        // Reset state
        showBurst = false
        burstScale = 0
        burstOpacity = 0
        particles = []
        
        // Icon Animation (Ported from icon.tapActive/tapCompleted)
        iconRotation = -15
        iconScale = 0.85
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconRotation = 0
            iconScale = 1.2 // Slight overshoot expansion on save
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                iconScale = 1.1 // Resting favorite scale
            }
        }
        
        // Generate Particles (Physics-based Distribution)
        var newParticles: [BookmarkParticle] = []
        let particleCount = 6
        for i in 0..<particleCount {
            let angle = (CGFloat(i) / CGFloat(particleCount)) * (2.0 * .pi)
            let radius = 24.0 + CGFloat.random(in: 0...10)
            let x = cos(angle) * radius
            let y = sin(angle) * radius * 0.75
            let scale = 0.8 + CGFloat.random(in: 0...0.5)
            newParticles.append(BookmarkParticle(x: x, y: y, scale: scale, delay: Double(i) * 0.04))
        }
        self.particles = newParticles
        
        // Execute Animations
        withAnimation(.easeOut(duration: 0.5)) {
            burstScale = 1.4
            burstOpacity = 0.4
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
            burstOpacity = 0
        }
        
        // NEW: Flash and then fade particles while they fly
        particleOpacity = 1.0 
        withAnimation(.easeOut(duration: 0.8)) {
            showBurst = true
            particleOpacity = 0
        }
    }
    
    // Damped Delta
    private func dampedDelta(_ input: CGFloat) -> CGFloat {
        if input <= 0 { return input }
        let slack: CGFloat = 40
        if input <= slack {
            return input
        } else {
            let overshoot = input - slack
            return slack + (40 * log10(1 + overshoot / 25))
        }
    }
}

// LIQUID BONE SHAPE
struct BoneCapsuleShape: Shape {
    var dragOffset: CGFloat
    
    var animatableData: CGFloat {
        get { dragOffset }
        set { dragOffset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        // OPTIMIZATION: Use System Capsule Path when idle (offset == 0)
        // This ensures perfect antialiasing matching the Preset list.
        if abs(dragOffset) < 1 {
            return Path(roundedRect: rect, cornerRadius: rect.height / 2)
        }
        
        var path = Path()
        
        // Fixed radius for the ends
        let radius: CGFloat = 25 
        let w = rect.width
        let h = rect.height
        
        // Standard Capsule Shape (No Squeeze)
        
        // Top Edge
        path.move(to: CGPoint(x: radius, y: 0))
        path.addLine(to: CGPoint(x: w - radius, y: 0))
        
        // Right Arc
        path.addArc(center: CGPoint(x: w - radius, y: radius),
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(90),
                    clockwise: false)
        
        // Bottom Edge
        path.addLine(to: CGPoint(x: radius, y: h))
        
        // Left Arc
        path.addArc(center: CGPoint(x: radius, y: radius),
                    radius: radius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(270),
                    clockwise: false)
        
        path.closeSubpath()
        return path
    }
}
