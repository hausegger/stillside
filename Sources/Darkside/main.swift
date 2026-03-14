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

    @Flag(name: .customLong("set-monitor"), help: "Pick target monitor interactively")
    var setMonitor = false

    mutating func run() throws {
        var config = ConfigManager.shared.load()

        if show && setHotkey == nil && !setMonitor {
            printConfig(config)
            return
        }

        var changed = false
        if let hotkey = setHotkey {
            config.hotkey = hotkey
            changed = true
        }
        if setMonitor {
            let monitors = MonitorManager.listMonitors()
            let items = monitors.map { m in
                let suffix = m.isPrimary ? " (primary)" : ""
                return TerminalPicker.Item(label: "\(m.index): \(m.name)\(suffix)", value: m.index)
            }
            if let selected = TerminalPicker.pick(title: "Select monitor:", items: items, initial: config.monitorIndex) {
                config.monitorIndex = selected
                changed = true
            }
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
