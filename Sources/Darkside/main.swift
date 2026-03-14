import AppKit
import ArgumentParser

struct Darkside: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Black out a secondary monitor with a global hotkey.",
        subcommands: [Config.self]
    )

    @Option(help: "Hotkey combo (e.g. cmd+option+b)")
    var hotkey: String?

    @Option(help: "Monitor index (1 = first secondary)")
    var monitor: Int?

    mutating func run() throws {
        var config = ConfigManager.shared.load()
        if let hotkey { config.hotkey = hotkey }
        if let monitor { config.monitorIndex = monitor }

        startApp(config: config)
    }
}

struct Config: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show or update saved configuration."
    )

    @Flag(help: "Print current config")
    var show = false

    @Option(name: .customLong("set-hotkey"), help: "Set hotkey combo")
    var setHotkey: String?

    @Option(name: .customLong("set-monitor"), help: "Set monitor index")
    var setMonitor: Int?

    mutating func run() throws {
        var config = ConfigManager.shared.load()

        if show && setHotkey == nil && setMonitor == nil {
            printConfig(config)
            return
        }

        var changed = false
        if let hotkey = setHotkey {
            config.hotkey = hotkey
            changed = true
        }
        if let monitor = setMonitor {
            config.monitorIndex = monitor
            changed = true
        }

        if changed {
            try ConfigManager.shared.save(config)
            print("Config saved.")
        }
        printConfig(config)
    }

    private func printConfig(_ config: DarksideConfig) {
        print("hotkey: \(config.hotkey)")
        print("monitor: \(config.monitorIndex)")
    }
}

func startApp(config: DarksideConfig) {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    let delegate = AppDelegate(config: config)
    app.delegate = delegate

    app.run()
}

do {
    var command: any ParsableCommand = try Darkside.parseAsRoot()
    try command.run()
} catch {
    Darkside.exit(withError: error)
}
