import Testing
@testable import TouchCore

@Test func slowLiftHasNoMomentum() {
    var m = Momentum(velocityX: 5, velocityY: -5)
    let step = m.next()
    #expect(step == nil)
}

@Test func firstStepIsVelocityTimesFrameInterval() throws {
    var m = Momentum(velocityX: 0, velocityY: 1200, frameInterval: 1.0 / 120, releaseBoost: 1)
    let first = m.next()
    let step = try #require(first)
    #expect(abs(step.dx) < 1e-9)
    #expect(abs(step.dy - 10) < 1e-9)
}

@Test func stepsDecayAndEventuallyStop() {
    var m = Momentum(velocityX: 3000, velocityY: 0, frameInterval: 1.0 / 120, decay: 0.95, minSpeed: 20, releaseBoost: 1)
    var steps: [Double] = []
    while let step = m.next() { steps.append(step.dx) }
    #expect(steps.count > 10 && steps.count < 200)
    #expect(zip(steps, steps.dropFirst()).allSatisfy { $0 > $1 })
    let total = steps.reduce(0, +)
    #expect(total < 3000.0 / 120 / (1 - 0.95))  // bounded by the geometric series
}

/// The owner's Magic Trackpad flicks (2026-11-04): first steps 75-149 pt at 60 Hz, glides of 1176-2447 pt
/// lasting 0.5-1.3 s, total ≈ 16.4 × the first step.
@Test func theDefaultGlideMatchesTheMeasuredTrackpad() throws {
    var m = Momentum(velocityX: 0, velocityY: 6000 / 1.3)          // a first step of 100 pt, mid-range of the flicks
    var steps: [Double] = []
    while let step = m.next() { steps.append(step.dy) }
    let first = try #require(steps.first)
    #expect(abs(first - 100) < 0.01)
    let total = steps.reduce(0, +)
    #expect(total / first > 15 && total / first < 17.5, "glide distance \(total / first) × the first step")
    let seconds = Double(steps.count) / 60
    #expect(seconds > 0.5 && seconds < 1.5, "glide lasts \(seconds) s")
}
