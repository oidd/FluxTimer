import SwiftUI


struct DragCapsuleView: View {
    @Binding var minutes: Int
    @Binding var isDragging: Bool
    @Binding var title: String
    var isFavorite: Bool
    var dragChanged: (CGFloat) -> Void
    var dragEnded: () -> Void
    var onCommit: () -> Void
    var onFavoriteToggle: () -> Void
    
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
    @State private var restingWidth: CGFloat = 0
    private let visualLimit: CGFloat = 120
    private let dragLogic = DragLogic() // Helper for reverse calc
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool // For input focus
    @State private var showManualInputHint = false // New state for hint
    
    private let l10n = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 0) {
            // Time Section
            HStack(spacing: 8) {
                BookmarkButton(isFavorite: isFavorite) {
                    if minutes > 0 {
                        onFavoriteToggle()
                    }
                }
                
                if isEditing {
                    TextField("0", value: $minutes, formatter: NumberFormatter())
                        .focused($isFocused)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(.plain)
                        .frame(width: 48) // Increased Width for 3 digits
                        .onSubmit {
                            isEditing = false
                        }
                        .onChange(of: isFocused) { focused in
                            if !focused { isEditing = false }
                        }
                } else {
                    // Display Logic: Show Hint or Time
                    if showManualInputHint {
                        Text(l10n.t("松手输入"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .offset(y: -0.5)
                    } else {
                        Text(String(format: l10n.t("%d min"), minutes))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .offset(y: -0.5)
                            .onTapGesture {
                                isEditing = true
                                isFocused = true
                            }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 38 * 0.42, style: .continuous).fill(.white.opacity(0.2)))
            .padding(.leading, 4)
            .fixedSize()
            
            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)
                .opacity(0.5)
            
            // TextField Section
            TextField(l10n.t("提醒事项..."), text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .padding(.leading, 4)
                .onSubmit { onCommit() }
                .frame(width: 112)
            
            Spacer(minLength: 0)
                .frame(width: max(0, restingWidth + (isDragging ? dampedDelta(dragOffset) : 0)))
            
            // Handle Section
            ZStack {
                Color.white.opacity(0.001)
                    .frame(width: 30, height: 50)
                    .contentShape(Rectangle())
                
                let isPlus = minutes > 0 && !isDragging
                ZStack {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(.white)
                            .frame(width: 2, height: 12)
                            .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
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
                if hover { NSCursor.openHand.push() } else { NSCursor.pop() }
            }
            .onTapGesture {
                if minutes > 0 && !isDragging { onCommit() }
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging { NSCursor.closedHand.push() }
                        isDragging = true
                        dragOffset = value.translation.width
                        
                        // Calculate raw minutes from logic (unlimited)
                        let rawMinutes = dragLogic.minutes(for: value.translation.width)
                        
                        if rawMinutes > 99 {
                            // Over limit -> Hint Mode
                            if minutes != 99 { minutes = 99 } // Stick at 99
                            if !showManualInputHint {
                                withAnimation { showManualInputHint = true }
                            }
                        } else {
                            // Normal Mode
                            if minutes != rawMinutes { minutes = rawMinutes }
                            if showManualInputHint {
                                withAnimation { showManualInputHint = false }
                            }
                        }
                        
                        dragChanged(value.translation.width)
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { dragOffset = 0 }
                        isDragging = false
                        NSCursor.pop()
                        dragEnded()
                        
                        // If hint was shown, trigger edit mode
                        if showManualInputHint {
                            showManualInputHint = false
                            // Must dispatch to avoid state conflicts during drag end processing
                            DispatchQueue.main.async {
                                isEditing = true
                                isFocused = true
                            }
                        }
                    }
            )
        }
        .frame(height: 50)
        .background(.ultraThinMaterial)
        .overlay(
            BoneCapsuleShape(dragOffset: isDragging ? dragOffset : 0)
                .stroke(Color(white: 1.0, opacity: 0.2), lineWidth: 2)
        )
        .clipShape(BoneCapsuleShape(dragOffset: isDragging ? dragOffset : 0))
        .fixedSize(horizontal: true, vertical: false)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .overlay(alignment: .topLeading) {
            endTimerPredictionView
        }
        .onChange(of: minutes) { newValue in
            // Clamp input -> 999
            if newValue > 999 { minutes = 999 }
            if newValue < 0 { minutes = 0 }
            
            // Sync width if not dragging
            if !isDragging {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    // If manually entered > 99, we still want the capsule to look "full" or similar.
                    // DragLogic.width(for:) will handle >99 by extending further, which is fine.
                    dragOffset = dragLogic.width(for: minutes)
                }
            }
        }
        .onAppear {
            // Initial sync
            if minutes > 0 {
                dragOffset = dragLogic.width(for: minutes)
            }
        }
    }
    
    @ViewBuilder
    private var endTimerPredictionView: some View {
        if minutes > 0 {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
                let timeString = endDate.formatted(date: .omitted, time: .shortened)
                let localizedFormat = LocalizationManager.shared.t("预计 %@ 结束计时")
                
                let isNextDay = !Calendar.current.isDate(Date(), inSameDayAs: endDate)
                let displayTime = isNextDay ? LocalizationManager.shared.t("次日") + " " + timeString : timeString
                
                Text(String(format: localizedFormat, displayTime))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 22 * 0.42, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22 * 0.42, style: .continuous)
                                    .strokeBorder(Color(white: 1.0, opacity: 0.15), lineWidth: 0.5)
                            )
                    )
                    .offset(y: -24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    
    private func dampedDelta(_ input: CGFloat) -> CGFloat {
        if input <= 0 { return input }
        let slack: CGFloat = 40
        if input <= slack { return input }
        return slack + (40 * log10(1 + (input - slack) / 25))
    }
}

struct BoneCapsuleShape: Shape {
    var dragOffset: CGFloat
    var animatableData: CGFloat {
        get { dragOffset }
        set { dragOffset = newValue }
    }
    func path(in rect: CGRect) -> Path {
        return Path(roundedRect: rect, cornerRadius: rect.height * 0.42, style: .continuous)
    }
}
