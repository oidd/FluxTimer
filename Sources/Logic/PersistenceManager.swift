import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let folderName = "倒计时"
    private let fileName = "presets.json"
    
    private var fileURL: URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folderURL = documentsURL.appendingPathComponent(folderName)
        
        // Ensure folder exists
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
        
        return folderURL.appendingPathComponent(fileName)
    }
    
    func savePresets(_ presets: [TimerPreset]) {
        guard let url = fileURL else { return }
        
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: url)
        } catch {
            print("Failed to save presets: \(error)")
        }
    }
    
    func loadPresets() -> [TimerPreset]? {
        guard let url = fileURL else { return nil }
        
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        
        do {
            let data = try Data(contentsOf: url)
            let presets = try JSONDecoder().decode([TimerPreset].self, from: data)
            return presets
        } catch {
            print("Failed to load presets: \(error)")
            return nil
        }
    }
}
