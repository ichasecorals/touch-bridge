import Foundation

/// The touch display's EDID identity, in one place so the pipeline, the
/// self-test and the Event Sink can't drift apart again.
///
/// `model == 0` is a weak key (many panels report zero), so matching should
/// prefer `nameHint`/serial where a name is available; vendor+model stay as
/// the CoreGraphics lookup because that is all `CGDisplayVendorNumber` gives.
public struct TouchDisplayIdentity: Equatable, Sendable, Codable {
    public var vendor: UInt32
    public var model: UInt32
    /// Substring of the display's `localizedName`, e.g. "SIBOLAN".
    public var nameHint: String
    /// Physical active area, for gesture thresholds in millimetres.
    public var widthMm: Double
    public var heightMm: Double

    public init(vendor: UInt32, model: UInt32, nameHint: String, widthMm: Double, heightMm: Double) {
        self.vendor = vendor
        self.model = model
        self.nameHint = nameHint
        self.widthMm = widthMm
        self.heightMm = heightMm
    }

    /// SIBOLAN FHD as measured on this Mac (BetterDisplay report + EDID,
    /// `Monitor/SIBOLAN FHD_report.txt`): vendor 20236 (SXL `0x4F0C`), model 0,
    /// serial `8R33926O00QS`, 339.85 × 189.84 mm, 1920×1080.
    public static let sibolanFHD = TouchDisplayIdentity(
        vendor: 20236, model: 0, nameHint: "SIBOLAN", widthMm: 339.85, heightMm: 189.84)

    /// A known panel by EDID vendor/model (for its physical size), or nil.
    public static func known(vendor: UInt32, model: UInt32) -> TouchDisplayIdentity? {
        [sibolanFHD, arzopa].first { $0.vendor == vendor && $0.model == model }
    }

    /// Previous hardware, kept for reference.
    public static let arzopa = TouchDisplayIdentity(
        vendor: 7908, model: 342, nameHint: "ARZOPA", widthMm: 309.3, heightMm: 173.9)
}
