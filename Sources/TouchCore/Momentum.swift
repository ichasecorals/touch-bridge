import Foundation

/// Scroll momentum after a flick: per-frame deltas (points) that decay geometrically.
///
/// Defaults measured from the owner's Magic Trackpad on macOS 27 (Event Sink, 2026-11-04): momentum steps
/// arrive at 60 Hz, keep about 93-95 % of the previous step, and add up to about 16.4 times the first step
/// (WebKit's own measurement of the platform glide: 16.7). The first step was 1.0-2.3 times the content's
/// speed at release (median 1.45); `releaseBoost` 1.3 sits inside that.
public struct Momentum: Sendable {
    private var vx: Double
    private var vy: Double
    public let frameInterval: Double
    private let decay: Double
    private let minSpeed: Double

    /// Velocities in points per second, at the moment the fingers lift.
    public init(velocityX: Double, velocityY: Double, frameInterval: Double = 1.0 / 60, decay: Double = 0.94,
                minSpeed: Double = 60, releaseBoost: Double = 1.3) {
        vx = velocityX * releaseBoost
        vy = velocityY * releaseBoost
        self.frameInterval = frameInterval
        self.decay = decay
        self.minSpeed = minSpeed
    }

    /// The next frame's delta, or nil once the motion has died out.
    public mutating func next() -> (dx: Double, dy: Double)? {
        guard hypot(vx, vy) >= minSpeed else { return nil }
        let step = (dx: vx * frameInterval, dy: vy * frameInterval)
        vx *= decay
        vy *= decay
        return step
    }
}
