import SwiftUI

struct PlusButton: View {
    var isExpanded: Bool
    var action: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial) // STANDARD
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 1) // STANDARD
                )
            
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(.primary)
                .rotationEffect(.degrees(isExpanded ? 45 : 0))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
        }
        .contentShape(Circle()) // Make sure the whole area is hit-testable
        .frame(width: 50, height: 50)
    }
}
