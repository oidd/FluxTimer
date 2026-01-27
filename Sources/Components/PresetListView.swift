import SwiftUI

struct TimerPreset: Identifiable {
    let id = UUID()
    let minutes: Int
    let title: String
}

struct PresetListView: View {
    var isVisible: Bool // Controlled by parent
    @Binding var presets: [TimerPreset] // Now dynamic
    var onSelect: (TimerPreset) -> Void
    var onDelete: (TimerPreset) -> Void // New Callback
    
    @State private var hoveredPresetID: UUID? // Local hover state for delete button
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
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
                        
                        // Delete Button (Visible on Hover)
                        if hoveredPresetID == preset.id {
                            Button(action: {
                                onDelete(preset)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold)) // Slightly bolder
                                    .foregroundColor(.secondary.opacity(0.7)) // Slightly transparent grey
                                    .padding(6)
                                    // Background Removed
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial) // STANDARD
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(.white.opacity(0.2), lineWidth: 1) // STANDARD
                    )
                }
                .buttonStyle(.plain)
                // Hover Detection for Row
                .onHover { hover in
                    if hover {
                        hoveredPresetID = preset.id
                    } else if hoveredPresetID == preset.id {
                        hoveredPresetID = nil
                    }
                }
                // Staggered Animation Logic
                .opacity(isVisible ? 1 : 0)
                .offset(y: isVisible ? 0 : -15)
                .animation(
                    .spring(response: 0.3, dampingFraction: 0.8)
                    .delay(Double(index) * 0.05), // Stagger delay
                    value: isVisible
                )
            }
        }
        .frame(width: 160) // Slightly wider for delete button
        // REMOVED PADDING .padding(.top, 10)
        
        // HOLE & GAP FIX:
        // Ensure the entire frame (including spacing and padding) is hit-testable.
        // Without this, hovering the "gaps" between items would lost hover state.
        .contentShape(Rectangle()) 
    }
}
