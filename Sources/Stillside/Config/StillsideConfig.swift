import Foundation

struct StillsideConfig: Codable {
    /// Monitor index: -1 = non-active (screen without cursor), 0+ = specific screen index.
    var hotkey: String
    var monitorIndex: Int

    static let nonActiveIndex = -1
    static let `default` = StillsideConfig(hotkey: "cmd+option+b", monitorIndex: nonActiveIndex)
}
