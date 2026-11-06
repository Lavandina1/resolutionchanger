import Cocoa

class StatusMenuController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    var displayManager: DisplayManager
    private let systemSettingsManager = SystemSettingsManager.shared
    
    override init() {
        self.displayManager = DisplayManager.shared
        super.init()
        self.setupStatusItem()
    }
    
    /// Creates the status bar item and attaches its menu.
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        
        if let button = statusItem.button {
            button.image = nil
            button.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            button.title = "RES"
            button.toolTip = "Resolution Changer"
        } else {
            NSLog("Resolution Changer: failed to create status item button")
        }
        
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        
        updateMenu()
    }
    
    /// Rebuilds the menu from the current display modes.
    private func updateMenu() {
        menu.removeAllItems()
        
        let currentResolution = displayManager.getCurrentResolution()
        let availableResolutions = displayManager.getAvailableResolutions()
        
        // Group resolutions by size and collect their refresh rates.
        var groupedResolutions: [(width: Int, height: Int, rates: [Double])] = []
        
        for res in availableResolutions {
            if let index = groupedResolutions.firstIndex(where: { $0.width == res.width && $0.height == res.height }) {
                if !groupedResolutions[index].rates.contains(res.refreshRate) {
                    groupedResolutions[index].rates.append(res.refreshRate)
                }
            } else {
                groupedResolutions.append((width: res.width, height: res.height, rates: [res.refreshRate]))
            }
        }
        
        // Add one menu item per resolution group.
        for group in groupedResolutions {
            let baseTitle = "\(group.width) × \(group.height)"
            
            // Parent item for the resolution.
            let parentItem = NSMenuItem(
                title: baseTitle,
                action: #selector(resolutionSelected(_:)),
                keyEquivalent: ""
            )
            parentItem.target = self
            
            // Show refresh rates from highest to lowest.
            let sortedRates = group.rates.sorted(by: >)
            
            // Prefer the current refresh rate when it exists.
            let fallbackHz = sortedRates.first ?? 60.0
            var targetHz = fallbackHz
            
            // Keep the current rate for the active resolution.
            if let current = currentResolution, current.width == group.width && current.height == group.height {
                if sortedRates.contains(current.refreshRate) {
                    targetHz = current.refreshRate
                }
            }
            
            let defaultResolutionObject = DisplayResolution(width: group.width, height: group.height, refreshRate: targetHz)
            parentItem.representedObject = defaultResolutionObject
            
            // Build the submenu for refresh rates.
            let subMenu = NSMenu()
            
            let headerItem = NSMenuItem(title: "Set Refresh Rate", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            subMenu.addItem(headerItem)
            subMenu.addItem(NSMenuItem.separator())
            
            for rate in sortedRates {
                let rateItem = NSMenuItem(
                    title: "\(Int(rate))Hz",
                    action: #selector(resolutionSelected(_:)),
                    keyEquivalent: ""
                )
                rateItem.representedObject = DisplayResolution(width: group.width, height: group.height, refreshRate: rate)
                rateItem.target = self
                
                // Mark the active resolution and refresh rate.
                if let current = currentResolution,
                   current.width == group.width &&
                   current.height == group.height &&
                   Int(current.refreshRate) == Int(rate) {
                    rateItem.state = .on
                    parentItem.state = .on
                    
                    // Mirror the exact checked refresh-rate object.
                    parentItem.representedObject = rateItem.representedObject
                }
                
                subMenu.addItem(rateItem)
            }
            
            parentItem.submenu = subMenu
            menu.addItem(parentItem)
        }
        
        menu.addItem(NSMenuItem.separator())

        let menuBarItem = NSMenuItem(
            title: "Menu Bar Behavior...",
            action: #selector(openMenuBarSettings(_:)),
            keyEquivalent: ""
        )
        menuBarItem.target = self
        menu.addItem(menuBarItem)

        let dockItem = NSMenuItem(
            title: "Automatically Hide Dock",
            action: #selector(dockVisibilityToggled(_:)),
            keyEquivalent: ""
        )
        dockItem.target = self
        dockItem.state = systemSettingsManager.dockAutomaticallyHides ? .on : .off
        menu.addItem(dockItem)

        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit Resolution Changer",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    /// Applies the chosen resolution and refresh rate.
    @objc private func resolutionSelected(_ sender: NSMenuItem) {
        var targetResolution = sender.representedObject as? DisplayResolution
        
        // Resolve the exact selection from the submenu when present.
        if let submenu = sender.submenu {
            var foundCheckedItem = false
            
            // Use the checked item if one exists.
            for item in submenu.items {
                if item.state == .on, let childRes = item.representedObject as? DisplayResolution {
                    targetResolution = childRes
                    foundCheckedItem = true
                    break
                }
            }
            
            // Otherwise, use the first valid submenu item.
            if !foundCheckedItem {
                for item in submenu.items {
                    // Skip the header and separator.
                    if item.isEnabled, let childRes = item.representedObject as? DisplayResolution {
                        targetResolution = childRes
                        break
                    }
                }
            }
        }
        
        if let resolution = targetResolution {
            _ = displayManager.setResolution(resolution)
            updateMenu()
        }
    }

    @objc private func openMenuBarSettings(_ sender: NSMenuItem) {
        systemSettingsManager.openMenuBarSettings()
    }

    @objc private func dockVisibilityToggled(_ sender: NSMenuItem) {
        _ = systemSettingsManager.setDockAutomaticallyHides(!systemSettingsManager.dockAutomaticallyHides)
        updateMenu()
    }

    
    /// Quits the app.
    @objc private func quitApp(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}

extension StatusMenuController: NSMenuDelegate {
    /// Refreshes the menu just before it opens.
    func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }
}
