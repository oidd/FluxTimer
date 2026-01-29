import SwiftUI

struct TimerPreset: Identifiable, Codable, Equatable {
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
                let isHovered = hoveredPresetID == preset.id
                
                Button(action: { onSelect(preset) }) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 30 * 0.42, style: .continuous)
                                .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                                .background(RoundedRectangle(cornerRadius: 30 * 0.42, style: .continuous).fill(.white.opacity(0.2)))
                                .frame(width: 30, height: 30)
                            
                            Text("\(preset.minutes)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        
                        MarqueeText(
                            text: preset.title,
                            font: .system(size: 14, weight: .medium, design: .rounded),
                            leftFade: 0,
                            rightFade: 5,
                            startDelay: 0.2,
                            alignment: .leading,
                            isHovering: isHovered
                        )
                        .foregroundColor(.primary)
                        .frame(height: 16)
                        
                        Spacer(minLength: 12) // Restore right margin
                        
                        // Delete Button (Shown in the expanded space)
                        if isHovered {
                            Button(action: {
                                onDelete(preset)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 24, height: 24)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(4)
                    .frame(width: isHovered ? 190 : 160, alignment: .leading) // DYNAMIC WIDTH
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 38 * 0.42, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 38 * 0.42, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hover in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        if hover {
                            hoveredPresetID = preset.id
                        } else if hoveredPresetID == preset.id {
                            hoveredPresetID = nil
                        }
                    }
                }
                .disabled(!isVisible)
                .opacity(isVisible ? 1.0 : 0)
                .offset(y: isVisible ? 0 : -15)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.8)
                    .delay(isVisible ? 
                           Double(index) * 0.05 : 
                           Double(presets.count - 1 - index) * 0.05), 
                    value: isVisible
                )
            }
        }
        .contentShape(Rectangle()) 
    }
}
