import AppKit

final class MonitorManager {
    /// Returns the target screen for the given monitor index.
    /// -1 = non-active (screen without cursor), 0+ = specific screen by stable index.
    static func targetScreen(monitorIndex: Int) -> NSScreen? {
        let screens = NSScreen.screens
        if monitorIndex == DarksideConfig.nonActiveIndex {
            return nonActiveScreen()
        }
        guard monitorIndex >= 0 && monitorIndex < screens.count else { return nil }
        return screens[monitorIndex]
    }

    /// Returns the screen that does NOT contain the mouse cursor.
    /// With 2 monitors, this is "the other one." With 1 monitor, returns nil.
    private static func nonActiveScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let nonActive = screens.filter { !NSMouseInRect(mouseLocation, $0.frame, false) }
        return nonActive.first
    }

    /// Returns a labeled list of all monitors for the picker.
    static func listMonitors() -> [(index: Int, name: String, label: String)] {
        var result: [(index: Int, name: String, label: String)] = []
        result.append((index: DarksideConfig.nonActiveIndex, name: "Non-active", label: "Non-active (screen without cursor)"))
        for (i, screen) in NSScreen.screens.enumerated() {
            let isPrimary = (screen == NSScreen.main)
            let suffix = isPrimary ? " (primary)" : ""
            result.append((index: i, name: screen.localizedName, label: "\(screen.localizedName)\(suffix)"))
        }
        return result
    }
}
