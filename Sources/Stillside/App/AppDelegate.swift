import AppKit
import HotKey

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: HotkeyManager!
    private var quitHotKey: HotKey?
    private var overlayController: OverlayController!

    private let initialConfig: StillsideConfig

    init(config: StillsideConfig) {
        self.initialConfig = config
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyConfig(initialConfig)

        quitHotKey = HotKey(key: .q, modifiers: [.command, .option])
        quitHotKey?.keyDownHandler = {
            NSApplication.shared.terminate(nil)
        }

        ConfigManager.shared.watch { [weak self] newConfig in
            self?.applyConfig(newConfig)
        }
    }

    private func applyConfig(_ config: StillsideConfig) {
        overlayController?.hide()
        overlayController = OverlayController(monitor: config.monitor)

        hotkeyManager = HotkeyManager { [weak self] in
            self?.overlayController.toggle()
        }
        hotkeyManager.register(hotkeyString: config.hotkey)
    }
}
