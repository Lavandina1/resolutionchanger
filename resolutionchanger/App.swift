import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusMenuController: StatusMenuController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        // Initialize the status menu controller which creates the menu bar item
        statusMenuController = StatusMenuController()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Allow the app to quit even though it doesn't have windows
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Prevent the app from reopening windows when clicked in Dock
        return false
    }
}
