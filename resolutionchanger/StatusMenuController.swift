import Cocoa

class StatusMenuController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    var displayManager: DisplayManager
    
    override init() {
        self.displayManager = DisplayManager.shared
        super.init()
        self.setupStatusItem()
    }
    
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
    
    private func updateMenu() {
        menu.removeAllItems()
        
        let currentResolution = displayManager.getCurrentResolution()
        let availableResolutions = displayManager.getAvailableResolutions()
        
        // Group the linear list into unique aspect boundaries [Width x Height: [RefreshRates]]
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
        
        // Populate menu items
        for group in groupedResolutions {
            let baseTitle = "\(group.width) × \(group.height)"
            
            // Primary Parent Menu Item
            let parentItem = NSMenuItem(
                title: baseTitle,
                action: #selector(resolutionSelected(_:)),
                keyEquivalent: ""
            )
            parentItem.target = self
            
            // Sort side options from highest performance frequency down to energy saver boundaries
            let sortedRates = group.rates.sorted(by: >)
            
            // FIXED: Explicitly pick the target refresh rate from available options
            let fallbackHz = sortedRates.first ?? 60.0
            var targetHz = fallbackHz
            
            // If this group matches the current resolution, try to use the current refresh rate
            if let current = currentResolution, current.width == group.width && current.height == group.height {
                if sortedRates.contains(current.refreshRate) {
                    targetHz = current.refreshRate
                }
            }
            
            let defaultResolutionObject = DisplayResolution(width: group.width, height: group.height, refreshRate: targetHz)
            parentItem.representedObject = defaultResolutionObject
            
            // CONSTRUCT SIDE MENU (SUBMENU) FOR REFRESH RATES
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
                
                // If it is the current active resolution and refresh rate, mark checkmarks on both parent and side elements
                if let current = currentResolution,
                   current.width == group.width &&
                   current.height == group.height &&
                   Int(current.refreshRate) == Int(rate) {
                    rateItem.state = .on
                    parentItem.state = .on
                    
                    // Keep the parent item synchronized with the exact active checked refresh rate object
                    parentItem.representedObject = rateItem.representedObject
                }
                
                subMenu.addItem(rateItem)
            }
            
            parentItem.submenu = subMenu
            menu.addItem(parentItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(
            title: "Quit Resolution Changer",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func resolutionSelected(_ sender: NSMenuItem) {
        var targetResolution = sender.representedObject as? DisplayResolution
        
        // Inspect the submenu context
        if let submenu = sender.submenu {
            var foundCheckedItem = false
            
            // Step 1: Look for an item that is already checked
            for item in submenu.items {
                if item.state == .on, let childRes = item.representedObject as? DisplayResolution {
                    targetResolution = childRes
                    foundCheckedItem = true
                    break
                }
            }
            
            // Step 2: FIX FOR HIGHEST PIXEL RESOLUTION JUMP BUG
            // If no item is checked (because you clicked a completely new resolution),
            // do not guess using a loose fallback. Explicitly grab the resolution object
            // from the very first valid option inside the submenu (which is your highest sorted Hz).
            if !foundCheckedItem {
                for item in submenu.items {
                    // Skip the descriptive header and separator rows
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

    
    @objc private func quitApp(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}

extension StatusMenuController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateMenu()
    }
}
