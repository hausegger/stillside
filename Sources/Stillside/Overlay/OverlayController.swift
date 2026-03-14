import AppKit

final class OverlayController {
    private var panel: OverlayPanel?
    private var animationView: CRTShutdownView?
    private let monitorIndex: Int

    var isActive: Bool { panel != nil }

    init(monitorIndex: Int) {
        self.monitorIndex = monitorIndex
    }

    func toggle() {
        if panel != nil {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        guard let screen = MonitorManager.targetScreen(monitorIndex: monitorIndex) else {
            NSSound.beep()
            return
        }

        let overlay = OverlayPanel(screen: screen)
        overlay.backgroundColor = .clear
        panel = overlay

        let crtView = CRTShutdownView(frame: overlay.contentView!.bounds)
        crtView.autoresizingMask = [.width, .height]
        overlay.contentView?.addSubview(crtView)
        animationView = crtView

        overlay.orderFrontRegardless()

        crtView.startAnimation { [weak self] in
            self?.animationView?.removeFromSuperview()
            self?.animationView = nil
            self?.panel?.backgroundColor = .black
        }
    }

    private func hide() {
        animationView?.stopAnimation()
        animationView = nil
        panel?.close()
        panel = nil
    }
}
