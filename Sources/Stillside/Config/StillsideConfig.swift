import Foundation

struct StillsideConfig: Codable, Equatable {
    /// Monitor target: -1 = non-active (screen without cursor), positive = CGDirectDisplayID.
    var hotkey: String
    var monitor: Int

    static let nonActiveMonitor = -1
    static let `default` = StillsideConfig(hotkey: "cmd+option+b", monitor: nonActiveMonitor)
}
