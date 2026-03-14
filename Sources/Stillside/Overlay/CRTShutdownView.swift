import AppKit

final class CRTShutdownView: NSView {
    private var displayLink: CVDisplayLink?
    private var startTime: CFTimeInterval = 0
    private var completion: (() -> Void)?

    // Animation timing (seconds)
    private let verticalCloseDuration: CFTimeInterval = 0.35
    private let lineNarrowDuration: CFTimeInterval = 0.2
    private let dotFadeDuration: CFTimeInterval = 0.3
    private var totalDuration: CFTimeInterval { verticalCloseDuration + lineNarrowDuration + dotFadeDuration }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func startAnimation(completion: @escaping () -> Void) {
        self.completion = completion
        startTime = CACurrentMediaTime()

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard let link else { return }

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        CVDisplayLinkSetOutputCallback(link, { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo else { return kCVReturnError }
            let view = Unmanaged<CRTShutdownView>.fromOpaque(userInfo).takeUnretainedValue()
            DispatchQueue.main.async {
                view.needsDisplay = true
            }
            return kCVReturnSuccess
        }, selfPtr)

        displayLink = link
        CVDisplayLinkStart(link)
    }

    func stopAnimation() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
        displayLink = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let elapsed = CACurrentMediaTime() - startTime
        let w = bounds.width
        let h = bounds.height
        let midY = h / 2
        let midX = w / 2

        // Clear everything (transparent)
        ctx.clear(bounds)

        if elapsed < verticalCloseDuration {
            // Phase 1: Black bars close from top and bottom, screen content visible in shrinking gap
            let progress = elapsed / verticalCloseDuration
            let eased = easeInCubic(progress)
            let gapHeight = max(2, h * (1.0 - eased))
            let barHeight = (h - gapHeight) / 2

            // Top black bar
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(CGRect(x: 0, y: h - barHeight, width: w, height: barHeight))
            // Bottom black bar
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: barHeight))

        } else if elapsed < verticalCloseDuration + lineNarrowDuration {
            // Phase 2: Full black, thin bright line narrows horizontally
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)

            let progress = (elapsed - verticalCloseDuration) / lineNarrowDuration
            let eased = easeInQuad(progress)
            let lineWidth = max(4, w * (1.0 - eased))
            let lineHeight: CGFloat = 1.5
            let lineRect = CGRect(x: midX - lineWidth / 2, y: midY - lineHeight / 2, width: lineWidth, height: lineHeight)

            drawGlow(ctx: ctx, rect: lineRect, intensity: 1.0 - progress * 0.3)

        } else if elapsed < totalDuration {
            // Phase 3: Dot fades out
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)

            let progress = (elapsed - verticalCloseDuration - lineNarrowDuration) / dotFadeDuration
            let intensity = 1.0 - easeInQuad(progress)
            let dotSize: CGFloat = 3
            let dotRect = CGRect(x: midX - dotSize / 2, y: midY - dotSize / 2, width: dotSize, height: dotSize)

            drawGlow(ctx: ctx, rect: dotRect, intensity: intensity * 0.7)

        } else {
            // Done — fill black
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)
            stopAnimation()
            completion?()
            completion = nil
        }
    }

    private func drawGlow(ctx: CGContext, rect: CGRect, intensity: Double) {
        let glowColor = NSColor(white: 0.7, alpha: intensity * 0.4)
        let coreColor = NSColor(white: 0.7, alpha: intensity)

        // Soft glow
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 15, color: glowColor.cgColor)
        ctx.setFillColor(coreColor.cgColor)
        ctx.fill(rect)
        ctx.restoreGState()

        // Bright core
        ctx.setFillColor(coreColor.cgColor)
        ctx.fill(rect)
    }

    private func easeInQuad(_ t: Double) -> Double {
        min(1, max(0, t * t))
    }

    private func easeInCubic(_ t: Double) -> Double {
        let clamped = min(1, max(0, t))
        return clamped * clamped * clamped
    }

    deinit {
        stopAnimation()
    }
}
