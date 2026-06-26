import Cocoa

struct DisplayResolution: Equatable, Hashable {
    let width: Int
    let height: Int
    let refreshRate: Double
    
    var description: String {
        if refreshRate > 0 {
            return "\(width) × \(height) @ \(Int(refreshRate))Hz"
        } else {
            return "\(width) × \(height)"
        }
    }
}

class DisplayManager {
    static let shared = DisplayManager()
    
    /// Get all available resolutions for the main display
    func getAvailableResolutions() -> [DisplayResolution] {
        // For now, return a common set of resolutions
        // In a production app, this would query the display using CoreGraphics
        let commonResolutions: [DisplayResolution] = [
            DisplayResolution(width: 3440, height: 1440, refreshRate: 60),
            DisplayResolution(width: 2560, height: 1600, refreshRate: 60),
            DisplayResolution(width: 2560, height: 1440, refreshRate: 60),
            DisplayResolution(width: 2560, height: 1440, refreshRate: 144),
            DisplayResolution(width: 2560, height: 1440, refreshRate: 165),
            DisplayResolution(width: 1920, height: 1440, refreshRate: 60),
            DisplayResolution(width: 1920, height: 1200, refreshRate: 60),
            DisplayResolution(width: 1920, height: 1080, refreshRate: 60),
            DisplayResolution(width: 1920, height: 1080, refreshRate: 120),
            DisplayResolution(width: 1920, height: 1080, refreshRate: 144),
            DisplayResolution(width: 1680, height: 1050, refreshRate: 60),
            DisplayResolution(width: 1600, height: 1200, refreshRate: 60),
            DisplayResolution(width: 1440, height: 900, refreshRate: 60),
            DisplayResolution(width: 1280, height: 1024, refreshRate: 60),
            DisplayResolution(width: 1280, height: 800, refreshRate: 60),
            DisplayResolution(width: 1024, height: 768, refreshRate: 60),
        ]
        
        // Filter to only resolutions that might be available on this display
        let current = getCurrentResolution()
        var resolutions = commonResolutions
        
        // Add current resolution if not in list
        if let current = current, !resolutions.contains(current) {
            resolutions.insert(current, at: 0)
        }
        
        return resolutions.sorted { a, b in
            if a.width != b.width {
                return a.width > b.width
            }
            if a.height != b.height {
                return a.height > b.height
            }
            return a.refreshRate > b.refreshRate
        }
    }
    
    /// Get the current resolution of the main display
    func getCurrentResolution() -> DisplayResolution? {
        guard let screen = NSScreen.main else { return nil }
        
        let width = Int(screen.frame.width)
        let height = Int(screen.frame.height)
        let refreshRate: Double = 60.0
        
        return DisplayResolution(width: width, height: height, refreshRate: refreshRate)
    }
    
    /// Set the main display to a specific resolution
    func setResolution(_ resolution: DisplayResolution) -> Bool {
        // For now, this is a placeholder
        // TODO: Implement actual resolution changing via CoreGraphics
        NSLog("Attempting to set resolution to \(resolution.description)")
        return false
    }
}
