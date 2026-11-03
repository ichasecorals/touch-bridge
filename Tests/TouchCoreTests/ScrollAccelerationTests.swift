import Testing
@testable import TouchCore

private let ms: UInt64 = 1_000_000

@Test func slowScrollsFollowTheFingersOneToOne() {
    var a = ScrollAcceleration()
    var total = 0.0
    for i in 0..<20 { total += a.apply(dx: 0, dy: 1, atNs: UInt64(i) * 16 * ms).dy }   // ~60 pt/s
    #expect(abs(total - 20) < 1e-9)
}

@Test func fastFlicksMoveTheContentAboutTwiceAsFar() {
    var a = ScrollAcceleration()
    var total = 0.0
    for i in 0..<6 { total += a.apply(dx: 0, dy: 30, atNs: UInt64(i) * 10 * ms).dy }  // 3000 pt/s
    #expect(total > 30 + 5 * 30 * 1.9, "the first frame has no speed yet; later ones get ~2×: \(total)")
}

@Test func theGainRisesSmoothlyWithSpeed() {
    let a = ScrollAcceleration()
    let gains = stride(from: 50.0, through: 3000, by: 50).map(a.gain(forSpeed:))
    #expect(gains.first == 1 && gains.last == 2)
    #expect(zip(gains, gains.dropFirst()).allSatisfy { $0 <= $1 })
    #expect(abs(a.gain(forSpeed: 346.4) - 1.5) < 0.01, "halfway in log speed between 100 and 1200 pt/s")
}

@Test func resetStartsANewScrollWithoutCarriedSpeed() {
    var a = ScrollAcceleration()
    for i in 0..<5 { _ = a.apply(dx: 0, dy: 30, atNs: UInt64(i) * 10 * ms) }
    a.reset()
    #expect(a.apply(dx: 0, dy: 30, atNs: 1_000 * ms).dy == 30)
}
