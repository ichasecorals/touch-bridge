import Foundation
import TouchCore
import TouchPlatform

/// Menu settings that survive restarts (UserDefaults of com.theofanis.touchbridge). "Enabled" and
/// "Dry Run" are deliberately per-session.
struct StoredSettings: Sendable {
    var delivery: DeliveryMode?          // nil = automatic
    var gesturesDirect = true
    var oneFingerScroll = true
    var returnFocus = false
    var threeFingerDrag: Bool
    var threeFingerAnchor: ThreeFingerAnchor = .centroid
    /// While on, the trackpad's settings decide three-finger drag, scroll, pinch, rotate and momentum.
    var followTrackpad = true
    /// Launchpad opens on the display with the Dock: what a pinch-in on the touch display does about it.
    var launchpadDock: LaunchpadDockMode = .bringDockAndReturn
    /// A Space switch by touch gives focus back to the app on the other display.
    var keepFocusOnSpaceSwitch = true
    /// Two-finger scrolls drive trackpad page swipes (Safari back/forward).
    var swipeBetweenPages = true
    var displayVendor: UInt32 = TouchDisplayIdentity.sibolanFHD.vendor
    var displayModel: UInt32 = TouchDisplayIdentity.sibolanFHD.model
    var displayNameHint: String = TouchDisplayIdentity.sibolanFHD.nameHint
    var displayWidthMm = TouchDisplayIdentity.sibolanFHD.widthMm
    var displayHeightMm = TouchDisplayIdentity.sibolanFHD.heightMm

    /// The chosen touch display, with its physical size, as the pipeline and self-test use it.
    var displayIdentity: TouchDisplayIdentity {
        TouchDisplayIdentity(vendor: displayVendor, model: displayModel, nameHint: displayNameHint,
                             widthMm: displayWidthMm, heightMm: displayHeightMm)
    }

    private static var defaults: UserDefaults { .standard }

    static func load() -> StoredSettings {
        let d = defaults
        var s = StoredSettings(threeFingerDrag: d.object(forKey: "threeFingerDrag") as? Bool ?? trackpadThreeFingerDrag())
        // UserDefaults hands integers back as NSNumber; the struct defaults cover missing keys.
        if let n = d.object(forKey: "displayVendor") as? NSNumber { s.displayVendor = n.uint32Value }
        if let n = d.object(forKey: "displayModel") as? NSNumber { s.displayModel = n.uint32Value }
        if let w = d.object(forKey: "displayWidthMm") as? Double, w > 0 { s.displayWidthMm = w }
        if let h = d.object(forKey: "displayHeightMm") as? Double, h > 0 { s.displayHeightMm = h }
        s.displayNameHint = d.string(forKey: "displayNameHint") ?? TouchDisplayIdentity.sibolanFHD.nameHint
        s.delivery = d.string(forKey: "delivery").flatMap(DeliveryMode.init(rawValue:))
        s.gesturesDirect = d.object(forKey: "gesturesDirect") as? Bool ?? true
        s.oneFingerScroll = d.object(forKey: "oneFingerScroll") as? Bool ?? true
        s.returnFocus = d.object(forKey: "returnFocus") as? Bool ?? false
        s.threeFingerAnchor = d.string(forKey: "threeFingerAnchor").flatMap(ThreeFingerAnchor.init(rawValue:)) ?? .centroid
        s.followTrackpad = d.object(forKey: "followTrackpad") as? Bool ?? true
        s.launchpadDock = d.string(forKey: "launchpadDock").flatMap(LaunchpadDockMode.init(rawValue:)) ?? .bringDockAndReturn
        s.keepFocusOnSpaceSwitch = d.object(forKey: "keepFocusOnSpaceSwitch") as? Bool ?? true
        s.swipeBetweenPages = d.object(forKey: "swipeBetweenPages") as? Bool ?? true
        return s
    }

    func save() {
        let d = Self.defaults
        d.set(delivery?.rawValue, forKey: "delivery")
        d.set(displayVendor, forKey: "displayVendor")
        d.set(displayModel, forKey: "displayModel")
        d.set(displayNameHint, forKey: "displayNameHint")
        d.set(displayWidthMm, forKey: "displayWidthMm")
        d.set(displayHeightMm, forKey: "displayHeightMm")
        d.set(gesturesDirect, forKey: "gesturesDirect")
        d.set(oneFingerScroll, forKey: "oneFingerScroll")
        d.set(returnFocus, forKey: "returnFocus")
        d.set(threeFingerDrag, forKey: "threeFingerDrag")
        d.set(threeFingerAnchor.rawValue, forKey: "threeFingerAnchor")
        d.set(followTrackpad, forKey: "followTrackpad")
        d.set(launchpadDock.rawValue, forKey: "launchpadDock")
        d.set(keepFocusOnSpaceSwitch, forKey: "keepFocusOnSpaceSwitch")
        d.set(swipeBetweenPages, forKey: "swipeBetweenPages")
    }

    func apply(to p: inout PipelineSettings, trackpad: TrackpadPreferences) {
        apply(to: &p)
        p.trackpad = followTrackpad ? trackpad : nil
    }

    private func apply(to p: inout PipelineSettings) {
        p.policy.forced = delivery
        p.policy.gesturesDirect = gesturesDirect
        p.display = displayIdentity
        p.oneFingerDrag = oneFingerScroll ? .scroll : .clickAndDrag
        p.focus = returnFocus ? .returnToPrevious : .followTouch
        p.threeFingerDrag = threeFingerDrag
        p.threeFingerAnchor = threeFingerAnchor
        p.launchpadDock = launchpadDock
        p.keepFocusOnSpaceSwitch = keepFocusOnSpaceSwitch
        p.swipeBetweenPages = swipeBetweenPages
    }

    /// The trackpad's "Three-finger drag" setting (System Settings → Accessibility → Pointer Control),
    /// used until the menu setting has been changed once. On if the key is missing.
    static func trackpadThreeFingerDrag() -> Bool {
        let value = CFPreferencesCopyAppValue("TrackpadThreeFingerDrag" as CFString, "com.apple.AppleMultitouchTrackpad" as CFString)
        return (value as? NSNumber)?.boolValue ?? true
    }
}
