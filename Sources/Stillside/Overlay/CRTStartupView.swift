import AppKit

final class CRTStartupView: NSView {
    private var displayLink: CVDisplayLink?
    private var startTime: CFTimeInterval = 0
    private var completion: (() -> Void)?
    private var isFinished = false

    // Mirror of shutdown timing
    private let dotFadeDuration: CFTimeInterval = 0.20
    private let lineExpandDuration: CFTimeInterval = 0.15
    private let verticalOpenDuration: CFTimeInterval = 0.30
    private var totalDuration: CFTimeInterval { dotFadeDuration + lineExpandDuration + verticalOpenDuration }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func startAnimation(displayID: CGDirectDisplayID = CGMainDisplayID(), completion: @escaping () -> Void) {
        self.completion = completion
        startTime = CACurrentMediaTime()

        var link: CVDisplayLink?
        CVDisplayLinkCreateWithCGDisplay(displayID, &link)
        guard let link else { return }

        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque())
        CVDisplayLinkSetOutputCallback(link, { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo else { return kCVReturnError }
            let view = Unmanaged<CRTStartupView>.fromOpaque(userInfo).takeUnretainedValue()
            DispatchQueue.main.async { [weak view] in
                view?.needsDisplay = true
            }
            return kCVReturnSuccess
        }, selfPtr)

        displayLink = link
        CVDisplayLinkStart(link)
    }

    func stopAnimation() {
        guard let link = displayLink else { return }
        displayLink = nil
        CVDisplayLinkStop(link)
        Unmanaged.passUnretained(self).release()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        let elapsed = CACurrentMediaTime() - startTime
        let w = bounds.width
        let h = bounds.height
        let midY = h / 2
        let midX = w / 2

        ctx.clear(bounds)

        if elapsed < dotFadeDuration {
            // Phase 1: Dot fades in at center
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)

            let progress = elapsed / dotFadeDuration
            let intensity = easeOutCubic(progress) * 0.7
            let dotSize: CGFloat = 3
            let dotRect = CGRect(x: midX - dotSize / 2, y: midY - dotSize / 2, width: dotSize, height: dotSize)
            CRTEffects.drawGlow(ctx: ctx, rect: dotRect, intensity: intensity)

        } else if elapsed < dotFadeDuration + lineExpandDuration {
            // Phase 2: Dot stretches into full-width horizontal line
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(bounds)

            let progress = (elapsed - dotFadeDuration) / lineExpandDuration
            let eased = easeOutCubic(progress)
            let lineWidth = max(4, w * eased)
            let lineHeight: CGFloat = 1.5
            let lineRect = CGRect(x: midX - lineWidth / 2, y: midY - lineHeight / 2, width: lineWidth, height: lineHeight)
            CRTEffects.drawGlow(ctx: ctx, rect: lineRect, intensity: 0.7 + progress * 0.3)

        } else if elapsed < totalDuration {
            // Phase 3: Bars open from center, revealing content with scanlines
            let progress = (elapsed - dotFadeDuration - lineExpandDuration) / verticalOpenDuration
            let eased = easeOutCubic(progress)
            let gapHeight = max(2, h * eased)
            let barHeight = (h - gapHeight) / 2

            // Scanlines over the revealed area — fade with expansion
            let revealedBottom = barHeight
            let revealedTop = h - barHeight
            let scanlineIntensity = 0.5 * (1.0 - progress * progress)
            if scanlineIntensity > 0.001 {
                drawScanlines(ctx: ctx, x: 0, y: revealedBottom, width: w,
                              height: revealedTop - revealedBottom, intensity: scanlineIntensity)
            }

            // Black bars
            if barHeight > 0 {
                ctx.setFillColor(NSColor.black.cgColor)
                ctx.fill(CGRect(x: 0, y: h - barHeight, width: w, height: barHeight))
                ctx.fill(CGRect(x: 0, y: 0, width: w, height: barHeight))
            }

        } else {
            // Done
            if !isFinished {
                isFinished = true
                DispatchQueue.main.async { [weak self] in
                    self?.stopAnimation()
                    self?.completion?()
                    self?.completion = nil
                }
            }
        }
    }

    // MARK: - Effects

    private func drawScanlines(ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, intensity: Double) {
        guard intensity > 0.001 else { return }
        let brightColor = NSColor(white: 1, alpha: intensity * 0.8).cgColor
        let darkColor = NSColor(white: 0, alpha: intensity * 0.8).cgColor
        let step: CGFloat = 5
        var lineY = y
        while lineY < y + height {
            ctx.setFillColor(brightColor)
            ctx.fill(CGRect(x: x, y: lineY, width: width, height: 1))
            ctx.setFillColor(darkColor)
            ctx.fill(CGRect(x: x, y: lineY + 1, width: width, height: 1))
            lineY += step
        }
    }

    // MARK: - Easing

    private func easeOutCubic(_ t: Double) -> Double {
        let clamped = min(1, max(0, t))
        let inv = 1 - clamped
        return 1 - inv * inv * inv
    }

    deinit {
        stopAnimation()
    }
}
