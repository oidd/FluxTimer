import SwiftUI

struct TimerPreset: Identifiable {
    let id = UUID()
    let minutes: Int
    let title: String
}

struct PresetListView: View {
    var isVisible: Bool // Controlled by parent
    var isFullVisibility: Bool // New: Controlled by specific area hover
    @Binding var presets: [TimerPreset] // Now dynamic
    var onSelect: (TimerPreset) -> Void
    var onDelete: (TimerPreset) -> Void // New Callback
    
    @State private var hoveredPresetID: UUID? // Local hover state for delete button
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                // Tiered Opacity Calculation for 'Peek' Mode
                // 1st (idx 0): 50%
                // 2nd (idx 1): 10% fading to 0% at bottom
                // 3rd+ (idx 2+): 0%
                let rowOpacity: Double = isFullVisibility ? 1.0 : (index == 0 ? 0.5 : (index == 1 ? 1.0 : 0.0))
                
                Button(action: { onSelect(preset) }) {
                    HStack {
                        ZStack {
                            Circle()
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                .background(Circle().fill(.white.opacity(0.2)))
                                .frame(width: 30, height: 30)
                            
                            Text("\(preset.minutes)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        
                        Text(preset.title)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Delete Button (Visible on Hover in Full Mode)
                        if isFullVisibility && hoveredPresetID == preset.id {
                            Button(action: {
                                onDelete(preset)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.7))
                                    .padding(6)
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hover in
                    if isFullVisibility { // Only track internal hover if fully visible
                        if hover {
                            hoveredPresetID = preset.id
                        } else if hoveredPresetID == preset.id {
                            hoveredPresetID = nil
                        }
                    }
                }
                .disabled(!isFullVisibility && index >= 2) // Disable hidden items
                .opacity(isVisible ? rowOpacity : 0)
                // Specific Gradient Mask for the 2nd Item in Peek Mode
                .mask {
                    if !isFullVisibility && index == 1 {
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.1), location: 0),
                                .init(color: .white.opacity(0.0), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color.white
                    }
                }
                .offset(y: isVisible ? 0 : -15)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.8)
                    .delay(isVisible ? Double(index) * 0.05 : 0), 
                    value: isVisible
                )
                .animation(.easeInOut(duration: 0.2), value: isFullVisibility)
            }
        }
        .frame(width: 160)
        .contentShape(Rectangle()) 
    }
}
