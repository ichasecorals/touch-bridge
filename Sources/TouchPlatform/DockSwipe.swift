import CoreGraphics
import Foundation

/// The trackpad's animated "dock swipes" (Mission Control, App Exposé, Spaces, Launchpad, Show Desktop),
/// synthesized as the private gesture events macOS 15 expects. The event format was learned from Mac Mouse Fix's
/// TouchSimulator (pre-macOS 27 path): per step, a type-30 event carrying a kIOHIDEventTypeDockSwipe subtype
/// with the phase, swipe type and accumulated progress, then a type-29 companion, both to the session tap.
/// The end event is re-sent after 0.2 s and 0.5 s because the system sometimes misses it under load.
///
/// macOS 27 no longer reads those CGEvent fields: the gesture must travel as an IOHIDEvent (type DockSwipe, with
/// motion, flavor and progress, plus a Velocity child on exit) attached to a type-30 CGEvent, with no type-29
/// companion. Ported from Mac Mouse Fix commit f92d2d53a (TouchSimulator.m, FixDockSwipes.m).
final class DockSwipe {
    enum Kind: Int64 {
        /// Spaces / full-screen apps (four fingers left / right).
        case horizontal = 1
        /// Mission Control (up) / App Exposé (down).
        case vertical = 2
        /// Launchpad (pinch in) / Show Desktop (spread out).
        case pinch = 3
    }

    enum Phase: Int64 { case began = 1, changed = 2, ended = 4, cancelled = 8 }

    private var originOffset = 0.0
    private var lastDelta = 0.0
    private var stepCount = 0
    private var beganNs: UInt64 = 0
    /// Recent steps, for the exit speed (macOS 27 decides completion from progress and this speed).
    private var recent: [(ns: UInt64, delta: Double)] = []
    private var resends: [DispatchWorkItem] = []
    private let queue: DispatchQueue
    var dryRun = false
    var log: (String) -> Void = { _ in }

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    /// `delta` is this step's progress; the system completes or cancels the swipe from the accumulated
    /// progress and the last step's direction when it ends.
    /// For experiments with type values beyond the known three.
    func postRaw(delta: Double, kind raw: Int64, phase: Phase) {
        rawKind = raw
        post(delta: delta, kind: .vertical, phase: phase)
        rawKind = nil
    }
    private var rawKind: Int64?

    func post(delta: Double, kind: Kind, phase requested: Phase, inverted: Bool = false) {
        var phase = requested
        switch phase {
        case .began:
            cancelResends()
            originOffset = delta
        case .changed:
            guard delta != 0 else { return }
            originOffset += delta
        case .ended, .cancelled:
            // Ending against the swipe's direction cancels it.
            if phase == .ended, (lastDelta < 0) != (originOffset < 0) { phase = .cancelled }
        }
        // Progress per second over the last 60 ms: a flick that slows in its final frame still counts as fast.
        let nowNs = DispatchTime.now().uptimeNanoseconds
        if phase == .began { recent = [] }
        if phase == .began || phase == .changed {
            recent.append((nowNs, delta))
            recent.removeAll { nowNs &- $0.ns > 100_000_000 }
        }
        let window = recent.filter { nowNs &- $0.ns <= 60_000_000 }
        let span = max(Double(nowNs &- (window.first?.ns ?? nowNs)) / 1e9, 0.008)
        let rate = window.reduce(0.0) { $0 + $1.delta } / span
        // One log line when a swipe begins and one when it ends, with its length, progress and exit speed.
        let ms = Int((DispatchTime.now().uptimeNanoseconds &- beganNs) / 1_000_000)
        switch phase {
        case .began:
            stepCount = 0
            beganNs = DispatchTime.now().uptimeNanoseconds
            log("dock swipe \(kind) began, first step \(String(format: "%.3f", delta))")
        case .changed:
            stepCount += 1
        case .ended, .cancelled:
            log("dock swipe \(kind) \(phase) (finger lift said \(requested)) at \(ms) ms after \(stepCount) steps, progress \(String(format: "%.3f", originOffset)), last step \(String(format: "%.3f", lastDelta)), speed \(String(format: "%.1f", rate))/s")
        }
        let exitSpeed = lastDelta * 100
        lastDelta = delta
        let made: (CGEvent, CGEvent?)?
        // macOS 27 exit speed in Mac Mouse Fix's units: the delta per ~8 ms frame × 300 (it observed ×300 there, ×100 before).
        if #available(macOS 27, *), let hid = makeHIDEvent(kind: kind, phase: phase, exitSpeed: rate * 0.008 * 300, inverted: inverted) {
            made = hid
        } else {
            made = makeEvents(kind: kind, phase: phase, exitSpeed: exitSpeed, inverted: inverted)
        }
        guard let (e30, e29) = made else { return }
        if dryRun {
            log("dry-run dock swipe \(kind) \(phase) offset \(String(format: "%.3f", originOffset))")
            return
        }
        e30.post(tap: .cgSessionEventTap)
        e29?.post(tap: .cgSessionEventTap)
        if phase == .ended || phase == .cancelled { scheduleResends(e30, e29) }
    }

    private var reportedPath = false

    /// macOS 27: the dock swipe as an IOHIDEvent attached to a type-30 CGEvent (nil if the private calls are missing).
    @available(macOS 27, *)
    private func makeHIDEvent(kind: Kind, phase: Phase, exitSpeed: Double, inverted: Bool) -> (CGEvent, CGEvent?)? {
        guard let event = CGEvent(source: nil) else { return nil }
        if let t = CGEventType(rawValue: 30) { event.type = t }
        event.setIntegerValueField(CGEventField(rawValue: 55)!, value: 30)   // the type field, as the old path sets it
        let hidPhase: HIDEventBridge.Phase = switch phase {
        case .began: .began
        case .changed: .changed
        case .ended: .ended
        case .cancelled: .cancelled
        }
        // The pinch's progress is pre-flipped for the old format's inverted flag; this format flips it itself.
        let attached = HIDEventBridge.attachDockSwipe(to: event, motion: Int(rawKind ?? kind.rawValue), phase: hidPhase,
                                                      progress: inverted ? -originOffset : originOffset,
                                                      exitSpeed: phase == .ended || phase == .cancelled ? exitSpeed : nil)
        if !reportedPath {
            reportedPath = true
            log(attached ? "dock swipes: macOS 27 format (IOHIDEvent attached)" : "dock swipes: macOS 27 HID calls not found; using the old event format")
        }
        return attached ? (event, nil) : nil
    }

    private func makeEvents(kind: Kind, phase: Phase, exitSpeed: Double, inverted: Bool) -> (CGEvent, CGEvent?)? {
        guard let e30 = CGEvent(source: nil), let e29 = CGEvent(source: nil) else { return nil }
        func f(_ n: UInt32) -> CGEventField { CGEventField(rawValue: n)! }
        let type = rawKind ?? kind.rawValue
        let typeBits = Double(Float(bitPattern: UInt32(type)))   // raw bits, like the trackpad's events

        e29.setDoubleValueField(f(55), value: 29)          // NSEventTypeGesture
        e29.setDoubleValueField(f(41), value: 33231)

        e30.setDoubleValueField(f(55), value: 30)
        e30.setDoubleValueField(f(110), value: 23)          // kIOHIDEventTypeDockSwipe
        e30.setDoubleValueField(f(132), value: Double(phase.rawValue))
        e30.setDoubleValueField(f(134), value: Double(phase.rawValue))
        e30.setDoubleValueField(f(124), value: originOffset)
        e30.setIntegerValueField(f(135), value: Int64(Float(originOffset).bitPattern))
        e30.setDoubleValueField(f(41), value: 33231)
        e30.setDoubleValueField(f(119), value: typeBits)
        e30.setDoubleValueField(f(139), value: typeBits)
        e30.setDoubleValueField(f(123), value: Double(type))
        e30.setDoubleValueField(f(165), value: Double(type))
        e30.setIntegerValueField(f(136), value: inverted ? 1 : 0)
        if phase == .ended || phase == .cancelled {
            e30.setDoubleValueField(f(129), value: exitSpeed)
            e30.setDoubleValueField(f(130), value: exitSpeed)
        }
        return (e30, e29)
    }

    private func scheduleResends(_ e30: CGEvent, _ e29: CGEvent?) {
        cancelResends()
        for delay in [0.2, 0.5] {
            let work = DispatchWorkItem {
                e30.post(tap: .cgSessionEventTap)
                e29?.post(tap: .cgSessionEventTap)
            }
            resends.append(work)
            queue.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    private func cancelResends() {
        resends.forEach { $0.cancel() }
        resends.removeAll()
    }
}
