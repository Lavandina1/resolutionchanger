import Cocoa

// Suppress AppIntents framework warnings during development
setenv("SUPPRESS_SHORTCUT_REGISTRATION_ERRORS", "1", 1)

// Custom main entry point to bypass SwiftUI/AppIntents initialization
@MainActor
func main() async {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}

await main()
