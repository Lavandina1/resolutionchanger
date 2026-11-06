# Resolution Changer

A lightweight macOS menu bar utility for quickly switching display resolutions.

## Features

- Lists available display resolutions and refresh rates
- Toggles automatic Dock hiding.
- Opens the macOS Control Center settings for menu bar behavior.
- Runs as a menu bar application without a Dock icon.

## Requirements

- macOS 26.5 or later.
- Xcode 26.6 or later.

## Build

Open `resolutionchanger.xcodeproj` in Xcode and run the `resolutionchanger` scheme.


Users may need to right-click the unsigned application and choose **Open** the first time they launch it.

## Permissions

Resolution Changer does not request Screen Recording or Accessibility permissions for display resolution changes or the Dock toggle. macOS may display its own confirmation when a display mode is changed.

The **Menu Bar Behavior...** menu item opens the relevant macOS Control Center settings page. The user can change that setting directly in System Settings.


## License

This project is distributed under the [MIT License](LICENSE).
