import Foundation
import AppKit

class DragLogic {
    // Non-linear mapping configuration
    private let zone1Limit: CGFloat = 200.0 // Pixels for 0-15 mins
    private let zone2Limit: CGFloat = 400.0 // Pixels for 15-60 mins
    
    // Snapping configuration
    private let snapThreshold: Int = 1 // +/- 1 minute around target
    private let snapTargets = [5, 10, 15, 30, 45, 60]
    
    // Haptic Feedback
    private let feedbackGenerator = NSHapticFeedbackManager.defaultPerformer
    private var lastSnappedValue: Int? = nil
    
    func minutes(for translation: CGFloat) -> Int {
        // Ensure positive drag
        let distance = max(0, translation)
        
        var calculatedMinutes: Double = 0
        
        if distance <= zone1Limit {
            // Zone 1: 0-15 mins. Slow.
            // 200px / 15mins = 13.3 px/min
            calculatedMinutes = (distance / zone1Limit) * 15.0
        } else if distance <= zone2Limit {
            // Zone 2: 15-60 mins. Normal.
            // (400-200)px / (60-15)mins = 200px / 45mins = 4.4 px/min
            // Faster change than Zone 1? User asked for "Slow" in Zone 1.
            // Wait, User said: "0-15 mins (High Freq): Drag Large Distance, Number changes Slow". Correct.
            // 13.3 px/min is slower change than 4.4 px/min?
            // No, larger pixels per minute means you have to drag FURTHER to change the minute.
            // So 13.3px per minute is SLOWER (more precise) than 4.4px per minute. Correct.
            let zone2Progress = (distance - zone1Limit) / (zone2Limit - zone1Limit)
            calculatedMinutes = 15.0 + (zone2Progress * 45.0)
        } else {
            // Zone 3: 60-99 mins. Fast.
            // 60-99 = 39 mins.
            // Let's say max drag is another 200px.
            // 200px / 39mins = 5.1 px/min.
            // Wait, to be FASTER, it should be FEWER pixels per minute.
            // e.g. 2 px per minute.
            let zone3Distance = distance - zone2Limit
            // Linear scaling for the rest
            calculatedMinutes = 60.0 + (zone3Distance / 5.0) // 5px per minute (Fast)
        }
        
        // Cap at 999
        calculatedMinutes = min(999, calculatedMinutes)
        
        // Snapping Logic with "Sticky" plateau
        var finalResult = Int(round(calculatedMinutes))
        
        for target in snapTargets {
            // Check if within "Sticky" range (e.g. +/- 0.8 minutes instead of 0.5)
            // This creates a "dead zone" where the value stays at the target
            if abs(calculatedMinutes - Double(target)) <= 0.8 {
                finalResult = target
                
                // Trigger Haptic only on initial entry to the zone
                if lastSnappedValue != target {
                    feedbackGenerator.perform(.alignment, performanceTime: .default)
                    lastSnappedValue = target
                }
                break 
            }
        }
        
        // Reset snap state if we left the zone
        if !snapTargets.contains(finalResult) {
            lastSnappedValue = nil
        }
        
        return finalResult
    }
    
    func width(for minutes: Int) -> CGFloat {
        let mins = Double(max(0, min(999, minutes)))
        
        if mins <= 15 {
            return (mins / 15.0) * zone1Limit
        } else if mins <= 60 {
            return zone1Limit + ((mins - 15.0) / 45.0) * (zone2Limit - zone1Limit)
        } else {
            return zone2Limit + (mins - 60.0) * 5.0
        }
    }
}
