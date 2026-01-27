import SwiftUI

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // QuadCurve for better control over "Flatness" and "Height"
        // Frame is 22x22
        
        // 1. Position (Higher)
        // Previous Arc was y ~ 15 to 19.
        // Let's move start points up to y ~ 12.
        let startY = rect.midY + 1 // y ~ 12
        // NARROWER: Increase inset from 4 to 6.
        let startX = rect.minX + 6 
        let endX = rect.maxX - 6
        
        // 2. Curvature (Less Curved)
        // Control point determines depth.
        // Adjusted slightly to keep it gentle with narrower width.
        let controlY = rect.midY + 4
        
        path.move(to: CGPoint(x: startX, y: startY))
        path.addQuadCurve(to: CGPoint(x: endX, y: startY),
                          control: CGPoint(x: rect.midX, y: controlY))
        
        return path
    }
}

struct DragCapsuleView: View {
    @Binding var minutes: Int
    @Binding var isDragging: Bool
    @Binding var title: String
    var dragChanged: (CGFloat) -> Void
    var dragEnded: () -> Void
    var onCommit: () -> Void
    var onFavorite: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var isFavorite: Bool = false
    
    // MICRO ANIMATION STATE
    @State private var smileOffset: CGFloat = 0
    
    // SPACER MEMORY
    @State private var restingWidth: CGFloat = 0
    
    // VISUAL LIMIT
    private let visualLimit: CGFloat = 120
    
    var body: some View {
        HStack(spacing: 0) {
            // Time Display
            Text("\(minutes) min")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .monospacedDigit()
                .padding(.horizontal, 10)
                .padding(.vertical, 12) // TALLER: ~44px height (Vs 50px container)
                .background(Capsule().fill(.white.opacity(0.2)))
                .padding(.leading, 4) // Reduce leading margin slightly to balance
                .fixedSize()
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 10)
                .opacity(0.5)

            // Input Field
            TextField("提醒事项...", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .onSubmit {
                    onCommit()
                }
                .frame(minWidth: 120) 
            
            // DYNAMIC SPACER
            Spacer(minLength: 0)
                .frame(width: max(0, restingWidth + (isDragging ? dampedDelta(dragOffset) : 0)))
            
            // Morphing Handle / Star
            ZStack {
                // Hit Area
                Color.white.opacity(0.001) 
                    .frame(width: 30, height: 50)
                    .contentShape(Rectangle())
                
                if minutes > 0 && !isDragging {
                    // STAR STATE
                    ZStack {
                        // 1. BASE: HOLLOW CUSTOM STAR (Always Visible)
                        if let nsImage = NSImage(contentsOfFile: "/Users/ivean/Documents/软件安装/我的扩展/倒计时/Sources/icons/五角星.svg") {
                            Image(nsImage: nsImage)
                                .resizable()
                                .renderingMode(.template) 
                                .foregroundColor(.white)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                        } else {
                            Image(systemName: "star")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }

                        // 2. FAVORITE: YELLOW SMILE CURVE (Overlay)
                        if isFavorite {
                            SmileShape()
                                .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round)) // THICKER (3)
                                .foregroundColor(.yellow)
                                .frame(width: 22, height: 22)
                                // MICRO-ANIMATION: Left-Right Sway
                                .offset(x: smileOffset)
                        }
                    }
                    .transition(.opacity)
                    
                } else {
                    // HANDLE STATE
                    HStack(spacing: 3) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(.white)
                                .frame(width: 2, height: 12)
                                .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.trailing, 8)
            .onHover { hover in
                if hover {
                    NSCursor.openHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            // Tap to Save
            .onTapGesture {
                if minutes > 0 && !isDragging {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isFavorite.toggle()
                    }
                     if isFavorite {
                         onFavorite()
                         // TRIGGER MICRO-ANIMATION
                         triggerSmileShake()
                     }
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
                        isFavorite = false 
                        smileOffset = 0 // Reset animation
                        dragOffset = value.translation.width
                        dragChanged(value.translation.width)
                    }
                    .onEnded { _ in
                        isDragging = false
                        let currentDelta = dampedDelta(dragOffset)
                        restingWidth = max(0, restingWidth + currentDelta)
                        dragOffset = 0
                        NSCursor.pop()
                        dragEnded()
                    }
            )
        }
        .frame(height: 50)
        .scaleEffect(x: 1.0, y: squeezeScale(dragOffset))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .fixedSize(horizontal: true, vertical: false)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    // Shake Logic
    private func triggerSmileShake() {
        // A simple 3-step shake
        // 0 -> -2 -> 2 -> -1 -> 1 -> 0
        let duration = 0.1
        withAnimation(Animation.linear(duration: duration)) { smileOffset = -2 }
        withAnimation(Animation.linear(duration: duration).delay(duration)) { smileOffset = 2 }
        withAnimation(Animation.linear(duration: duration).delay(duration * 2)) { smileOffset = -1 }
        withAnimation(Animation.linear(duration: duration).delay(duration * 3)) { smileOffset = 1 }
        withAnimation(Animation.linear(duration: duration).delay(duration * 4)) { smileOffset = 0 }
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
    
    // Squeeze Logic
    private func squeezeScale(_ input: CGFloat) -> CGFloat {
        if !isDragging { return 1.0 }
        if input < 0 { return 1.0 }
        let slack: CGFloat = 80
        if input <= slack {
            return 1.0
        } else {
            let overshoot = input - slack
            return max(0.92, 1.0 - (overshoot / 2000.0))
        }
    }
}
