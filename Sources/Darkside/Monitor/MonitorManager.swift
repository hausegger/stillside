import AppKit

final class MonitorManager {
    /// Returns the target screen for the given monitor index.
    /// Index 0 = primary monitor, 1 = first secondary, 2 = second secondary, etc.
    static func targetScreen(monitorIndex: Int) -> NSScreen? {
        if monitorIndex == 0 {
            return NSScreen.main
        }
        let secondaries = NSScreen.screens.filter { $0 != NSScreen.main }
        let index = monitorIndex - 1
        guard index >= 0 && index < secondaries.count else { return nil }
        return secondaries[index]
    }

    /// Returns a labeled list of all monitors: (index, name, isPrimary).
    static func listMonitors() -> [(index: Int, name: String, isPrimary: Bool)] {
        guard let main = NSScreen.main else { return [] }
        var result: [(index: Int, name: String, isPrimary: Bool)] = []
        result.append((index: 0, name: main.localizedName, isPrimary: true))
        let secondaries = NSScreen.screens.filter { $0 != main }
        for (i, screen) in secondaries.enumerated() {
            result.append((index: i + 1, name: screen.localizedName, isPrimary: false))
        }
        return result
    }
}
