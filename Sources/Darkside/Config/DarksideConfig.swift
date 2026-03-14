import Foundation

struct DarksideConfig: Codable {
    /// Monitor index: -1 = non-active (screen without cursor), 0+ = specific screen index.
    var hotkey: String
    var monitorIndex: Int

    static let nonActiveIndex = -1
    static let `default` = DarksideConfig(hotkey: "cmd+option+b", monitorIndex: nonActiveIndex)
}
