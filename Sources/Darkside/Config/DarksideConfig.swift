import Foundation

struct DarksideConfig: Codable {
    var hotkey: String
    var monitorIndex: Int

    static let `default` = DarksideConfig(hotkey: "cmd+option+b", monitorIndex: 1)
}
