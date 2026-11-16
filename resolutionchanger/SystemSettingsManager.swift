import Cocoa

final class SystemSettingsManager {
    static let shared = SystemSettingsManager()

    private init() {}

    @discardableResult
    func openMenuBarSettings() -> Bool {
        guard let settingsURL = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") else {
            return false
        }

        return NSWorkspace.shared.open(settingsURL)
    }

    var dockAutomaticallyHides: Bool {
        UserDefaults(suiteName: "com.apple.dock")?.bool(forKey: "autohide") ?? false
    }

    @discardableResult
    func setDockAutomaticallyHides(_ hides: Bool) -> Bool {
        let succeeded = runDefaults(arguments: ["write", "com.apple.dock", "autohide", "-bool", hides ? "true" : "false"])

        if succeeded {
            restartProcess(named: "Dock")
        }

        return succeeded
    }

    private func runDefaults(arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func restartProcess(named name: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = [name]

        do {
            try process.run()
        } catch {
            NSLog("Resolution Changer: failed to restart %@", name)
        }
    }

}