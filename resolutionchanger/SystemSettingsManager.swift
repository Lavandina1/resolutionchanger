import Cocoa

enum MenuBarVisibility: String, CaseIterable {
    case always = "Always"
    case desktop = "Only on Desktop"
    case fullScreen = "Only in Full Screen"
    case never = "Never"
}

final class SystemSettingsManager {
    static let shared = SystemSettingsManager()

    private let controlCenterDomain = "com.apple.controlcenter"
    private let menuBarOptionKey = "AutoHideMenuBarOption"
    private let menuBarHiddenKey = "_HIHideMenuBar"
    private let menuBarVisibleInFullScreenKey = "AppleMenuBarVisibleInFullscreen"

    private init() {}

    var menuBarVisibility: MenuBarVisibility {
        if let option = UserDefaults(suiteName: controlCenterDomain)?.object(forKey: menuBarOptionKey) as? NSNumber,
           let visibility = MenuBarVisibility(controlCenterOption: option.intValue) {
            return visibility
        }

        let hidesOnDesktop = UserDefaults.standard.bool(forKey: menuBarHiddenKey)
        let visibleInFullScreen = UserDefaults.standard.bool(forKey: menuBarVisibleInFullScreenKey)

        switch (hidesOnDesktop, visibleInFullScreen) {
        case (true, false):
            return .always
        case (true, true):
            return .desktop
        case (false, false):
            return .fullScreen
        case (false, true):
            return .never
        }
    }

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

private extension MenuBarVisibility {
    init?(controlCenterOption: Int) {
        switch controlCenterOption {
        case 0:
            self = .always
        case 1:
            self = .desktop
        case 2:
            self = .fullScreen
        case 3:
            self = .never
        default:
            return nil
        }
    }

}