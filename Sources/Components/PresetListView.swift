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
    var lastRecord: TimerPreset? = nil // Optional last finished record
    
    var onSelect: (TimerPreset) -> Void
    var onDelete: (TimerPreset) -> Void // New Callback
    var onFavoriteLast: (TimerPreset) -> Void // Callback for recent record
    
    @State private var hoveredPresetID: UUID? // Local hover state for delete button
    @State private var isRecentHovered: Bool = false
    
    private let l10n = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // 1. Last Record (Recent)
            if let recent = lastRecord {
                presetRow(preset: recent, isRecent: true)
            }
            
            // 2. Saved Presets
            ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                presetRow(preset: preset, isRecent: false, index: index)
            }
        }
        .contentShape(Rectangle()) 
    }
    
    @ViewBuilder
    private func presetRow(preset: TimerPreset, isRecent: Bool, index: Int = 0) -> some View {
        let isHovered = isRecent ? isRecentHovered : (hoveredPresetID == preset.id)
        let effectiveIndex = isRecent ? 0 : (lastRecord != nil ? index + 1 : index)
        
        Button(action: { onSelect(preset) }) {
            HStack(spacing: 0) {
                // Minutes Bubble
                ZStack {
                    RoundedRectangle(cornerRadius: 30 * 0.42, style: .continuous)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 30 * 0.42, style: .continuous).fill(.white.opacity(0.2)))
                        .frame(width: 30, height: 30)
                    
                    Text("\(preset.minutes)")
                        .font(.system(size: 12, weight: .bold))
                }
                
                // Title
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 16)
                .padding(.leading, 8)
                
                if isHovered {
                    Spacer(minLength: 4)
                    // Right-side Action (Expandable)
                    if isRecent {
                        BookmarkButton(isFavorite: presets.contains { $0.minutes == preset.minutes && $0.title == preset.title }) {
                            onFavoriteLast(preset)
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Button(action: { onDelete(preset) }) {
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
                } else if isRecent {
                    // Right-align the "Recent" tag to save space for the title
                    Spacer(minLength: 4)
                    Text(l10n.t("最近"))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.15)))
                        .fixedSize()
                        .transition(.opacity)
                } else {
                    Spacer(minLength: 8)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6) // Symmetric row padding
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
                if isRecent {
                    isRecentHovered = hover
                } else {
                    if hover {
                        hoveredPresetID = preset.id
                    } else if hoveredPresetID == preset.id {
                        hoveredPresetID = nil
                    }
                }
            }
        }
        .disabled(!isVisible)
        .opacity(isVisible ? 1.0 : 0)
        .offset(y: isVisible ? 0 : -15)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.8)
            .delay(isVisible ? 
                   Double(effectiveIndex) * 0.05 : 
                   Double((presets.count + (lastRecord != nil ? 1 : 0)) - 1 - effectiveIndex) * 0.05), 
            value: isVisible
        )
    }
}
