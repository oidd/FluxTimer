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
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Delete Button (Visible on Hover)
                        if hoveredPresetID == preset.id {
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
                    .clipShape(RoundedRectangle(cornerRadius: 38 * 0.42, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 38 * 0.42, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .onHover { hover in
                    if hover {
                        hoveredPresetID = preset.id
                    } else if hoveredPresetID == preset.id {
                        hoveredPresetID = nil
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
        .frame(width: 160)
        .contentShape(Rectangle()) 
    }
}
