import Cocoa
import CoreGraphics
import ApplicationServices


// MARK: - Global Display Options Configuration
let displayOptions = [
    kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue
] as CFDictionary

// MARK: - NSScreen Extension
extension NSScreen {
    /// Safely extracts the CoreGraphics display ID from the screen's device description.
    var displayID: CGDirectDisplayID? {
        return deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }
}

// MARK: - DisplayResolution
struct DisplayResolution: Equatable, Hashable, CustomStringConvertible {
    let width: Int
    let height: Int
    let refreshRate: Double
    let systemMode: CGDisplayMode? // Safe native reference to the internal configuration object
    
    init(width: Int, height: Int, refreshRate: Double, systemMode: CGDisplayMode? = nil) {
        self.width = width
        self.height = height
        self.refreshRate = refreshRate
        self.systemMode = systemMode
    }
    
    static func == (lhs: DisplayResolution, rhs: DisplayResolution) -> Bool {
        return lhs.width == rhs.width && lhs.height == rhs.height && Int(lhs.refreshRate) == Int(rhs.refreshRate)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(width)
        hasher.combine(height)
        hasher.combine(Int(refreshRate))
    }
    
    var description: String {
        if refreshRate > 0 {
            return "\(width) × \(height) @ \(Int(refreshRate))Hz"
        } else {
            return "\(width) × \(height)"
        }
    }
}

// MARK: - DisplayManager
class DisplayManager {
    static let shared = DisplayManager()
    
    private var initialized = false
    private var resolutionsCache: [DisplayResolution] = []
    
    private init() {}
    
    func initialize() {
        initialized = true
        _ = getAvailableResolutions()
    }
    
    /// Extract every unique display configuration available natively via CoreGraphics
    func getAvailableResolutions() -> [DisplayResolution] {
        guard let mainScreen = NSScreen.main, let displayID = mainScreen.displayID else {
            return []
        }
        
        guard let modes = CGDisplayCopyAllDisplayModes(displayID, displayOptions) as? [CGDisplayMode] else {
            return []
        }
        
        var uniqueResolutions = Set<DisplayResolution>()
        
        for mode in modes {
            // mode.width and mode.height automatically report user-facing logical points (scaled layouts)
            let logicalWidth = mode.width
            let logicalHeight = mode.height
            let hz = mode.refreshRate
            
            // Filter out microscopic system rendering profiles below 800px width
            if logicalWidth >= 800 {
                let res = DisplayResolution(
                    width: logicalWidth,
                    height: logicalHeight,
                    refreshRate: hz,
                    systemMode: mode
                )
                uniqueResolutions.insert(res)
            }
        }
        
        resolutionsCache = Array(uniqueResolutions).sorted {
            if $0.width == $1.width {
                if $0.height != $1.height {
                    return $0.height < $1.height
                }
                return $0.refreshRate > $1.refreshRate
            }
            return $0.width < $1.width
        }
        
        return resolutionsCache
    }
    
    func getResolutions(for screen: NSScreen) -> [DisplayResolution]? {
        return getAvailableResolutions()
    }
    
    /// Reads what layout the monitor is tracking natively right now
    func getCurrentResolution(for screen: NSScreen?) -> DisplayResolution? {
        guard let targetScreen = screen ?? NSScreen.main,
              let displayID = targetScreen.displayID,
              let currentMode = CGDisplayCopyDisplayMode(displayID) else {
            return nil
        }
        
        return DisplayResolution(
            width: currentMode.width,
            height: currentMode.height,
            refreshRate: currentMode.refreshRate,
            systemMode: currentMode
        )
    }
    
    func getCurrentResolution() -> DisplayResolution? {
        return getCurrentResolution(for: nil)
    }
    
    /// Sets the screen resolution using the CoreGraphics display mode API
    func setResolution(_ resolution: DisplayResolution) -> Bool {
        guard let mainScreen = NSScreen.main, let displayID = mainScreen.displayID else {
            return false
        }
        
        let allModes = getAvailableResolutions()
        let matched = allModes.first { $0 == resolution }
        
        guard let targetMode = matched, let modeToSet = targetMode.systemMode else {
            return false
        }
        
        var configRef: CGDisplayConfigRef?
        guard CGBeginDisplayConfiguration(&configRef) == .success, let config = configRef else {
            return false
        }
        
        let result = CGDisplaySetDisplayMode(displayID, modeToSet, nil)
        return result == .success
    }

}
