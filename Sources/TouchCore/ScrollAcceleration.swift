import Foundation

/// Trackpad-style acceleration for finger scrolls: slow movement follows the fingers one to one, fast movement
/// moves the content further than the fingers.
///
/// Calibrated against the owner's Magic Trackpad (Event Sink, 2026-11-04): slow 3 cm scrolls moved content
/// 118-167 pt, about what the touchscreen gives one to one (3 cm = 170 pt on the SIBOLAN), while fast flicks
/// moved it 180-365 pt during contact, about twice a ~2.5 cm touch flick. The trackpad reports only already
/// accelerated travel, so the top of the curve is an estimate: tune `maxGain` / `fastSpeed` by feel.
public struct ScrollAcceleration: Sendable {
    /// At or below this finger speed (points per second), content follows the fingers one to one.
    public var slowSpeed: Double
    /// At or above this speed, content moves `maxGain` times as far as the fingers.
    public var fastSpeed: Double
    public var maxGain: Double
    private var speed = 0.0
    private var lastNs: UInt64?

    public init(slowSpeed: Double = 100, fastSpeed: Double = 1200, maxGain: Double = 2.0) {
        self.slowSpeed = slowSpeed
        self.fastSpeed = fastSpeed
        self.maxGain = maxGain
    }

    /// The gain at a finger speed: 1 below `slowSpeed`, rising with the logarithm of the speed to `maxGain`.
    public func gain(forSpeed s: Double) -> Double {
        guard maxGain > 1, s > slowSpeed else { return 1 }
        guard s < fastSpeed else { return maxGain }
        return 1 + (maxGain - 1) * log(s / slowSpeed) / log(fastSpeed / slowSpeed)
    }

    /// Starts a new scroll.
    public mutating func reset() {
        speed = 0
        lastNs = nil
    }

    /// Scales one frame's finger movement (points) by the gain at the current, lightly smoothed finger speed.
    public mutating func apply(dx: Double, dy: Double, atNs now: UInt64) -> (dx: Double, dy: Double) {
        if let last = lastNs, now > last {
            let instant = hypot(dx, dy) / max(Double(now - last) / 1e9, 0.004)
            speed = speed == 0 ? instant : (speed + instant) / 2
        }
        lastNs = now
        let g = gain(forSpeed: speed)
        return (dx * g, dy * g)
    }
}
