import SwiftUI

struct SuperKeyHUDView: View {
    let inputText: String
    @State private var languageUpdate = UUID()
    
    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text(LocalizationManager.shared.t("倒计时"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            // Main Input Display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(inputText.isEmpty ? "0" : inputText)
                    .font(.system(size: 64, weight: .thin))
                    .monospacedDigit()
                    .foregroundColor(inputText.isEmpty ? .secondary.opacity(0.3) : .primary)
                
                Text(LocalizationManager.shared.t("分钟"))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            .frame(height: 80)
            
            // Instruction
            Text(inputText.isEmpty ? LocalizationManager.shared.t("保持按住修饰键，输入数字") : LocalizationManager.shared.t("松开修饰键开始计时"))
                .font(.system(size: 12))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(minWidth: 220) // Natural width stability
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        .id(languageUpdate)
        .onReceive(NotificationCenter.default.publisher(for: LocalizationManager.languageChangedNotification)) { _ in
            languageUpdate = UUID()
        }
    }
}
