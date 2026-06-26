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
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        
        // Set the menu bar text label
        if let button = statusItem.button {
            button.image = nil
            button.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            button.title = "RES"
            button.toolTip = "Resolution Changer"
        } else {
            NSLog("Resolution Changer: failed to create status item button")
        }
        
        // Create the main menu
        menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        
        // Populate menu items
        updateMenu()
    }
    
    private func updateMenu() {
        menu.removeAllItems()
        
        let displayManager = self.displayManager
        let currentResolution = displayManager.getCurrentResolution()
        let availableResolutions = displayManager.getAvailableResolutions()
        
        // Add resolution options
        for resolution in availableResolutions {
            let menuItem = NSMenuItem(
                title: resolution.description,
                action: #selector(resolutionSelected(_:)),
                keyEquivalent: ""
            )
            menuItem.representedObject = resolution
            menuItem.target = self
            
            // Add checkmark for current resolution
            if let current = currentResolution,
               current.width == resolution.width && current.height == resolution.height {
                menuItem.state = .on
            }
            
            menu.addItem(menuItem)
        }
        
        // Add separator before quit button
        menu.addItem(NSMenuItem.separator())
        
        // Add quit button
        let quitItem = NSMenuItem(
            title: "Quit Resolution Changer",
            action: #selector(quitApp(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    @objc private func resolutionSelected(_ sender: NSMenuItem) {
        if let resolution = sender.representedObject as? DisplayResolution {
            _ = displayManager.setResolution(resolution)
            // Update menu to show new checkmark
            updateMenu()
        }
    }
    
    @objc private func quitApp(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}

extension StatusMenuController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh the menu when it opens to ensure current resolution is correct
        updateMenu()
    }
}
