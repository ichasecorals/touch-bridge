# TouchBridge — agent notes

## Commands

- `swift build` — quick check. Expect warnings: `ImplicitStrongCapture` in `MenuBarApp.swift`, `SendableClosureCaptures` in `InputPipeline.swift:436`, linker missing-CLT-framework-search-path. Do not "fix" by silencing globally.
- `swift test` — full suite (unit + delivery + panel-replay). **Requires Xcode; fails on CommandLineTools-only** with `TestingMacros … plugin for module 'TestingMacros' not found`. `swift test --filter <TestName>` for one test.
- `./scripts/bundle.sh` — builds `build/TouchBridge.app` (dev copy). `./scripts/install.sh` — bundles + rsyncs to `~/Applications/TouchBridge.app` + restarts login item; quits running app first. Rebuilding never touches the installed copy.
- Signing: `TOUCHBRIDGE_SIGN_IDENTITY` (default `TouchBridge Dev`). Ad-hoc fallback works but macOS forgets Accessibility/Input Monitoring grants on every rebuild.
- Permissions for any live run: Accessibility (+ Input Monitoring if asked), then quit + restart the app.

## Architecture (Package.swift)

- `Sources/TouchCore` — pure Swift, no system frameworks. `GestureRecognizer` (state machine), `ReportParser`, `ContactTracker`, `TrackpadPreferences`, `DeliveryPolicy`. Fully unit-testable.
- `Sources/TouchPlatform` — macOS I/O only: `HIDTouchSource`, `InputPipeline` (routing), `Deliverer`/`DockSwipe` (event synthesis), `SystemUISelfTest`, diagnostics.
- `Sources/TouchBridgeApp` — menu-bar shell: `MenuBarApp`, `StoredSettings`, `EventSink`, `Probe`.
- `Tests/TouchCoreTests/Fixtures/*.jsonl` — real panel recording replayed by tests. Add new recordings here when changing the parser.

## Gotchas — do not reintroduce

- **Finger counting is independent of three-finger drag.** `.twoFinger` tracks a third finger in `additional` when drag is off, and resting extras are tracked in `.oneFinger` either way; `startMultiFinger` promotes from `.threeFinger`, `.twoFinger` (also from a just-started scroll, which it ends) and `.oneFinger` — so 4-finger dock swipes work with drag off while 3 fingers still scroll. Do not re-gate promotion on `config.threeFingerDrag`.
- **A dock swipe ends at two fingers, not at the first lift.** One finger leaving `.multiFinger` while three remain carries on from the remaining fingers (`lastCentroidMm`/`lastSpreadMm` reset, no jump). Touchscreen swipes down ended at 0-40 ms otherwise.
- **Scroll feel was measured from the owner's Magic Trackpad (Event Sink, 2026-11-04):** momentum at 60 Hz, ×0.93-0.95 per step, total ≈ 16.4 × first step (WebKit: 16.7), first step ≈ 1.0-2.3 × release speed → `Momentum` defaults 1/60 s, 0.94, minSpeed 60, releaseBoost 1.3. The trackpad only reports already-accelerated travel (HID child and vendor event agree), so `ScrollAcceleration` (1:1 below 100 pt/s, log-rising to 2× at 1200 pt/s) is calibrated from content distances, not finger mm.
- **Dock-swipe tuning was measured on this panel (macOS 27):** `dockSwipeMmPerUnit` 40 (80 left 1-2 cm swipes at 0.15-0.3 progress, flaky), pinch needs `dockPinchDecisionMm` 10 and 2× travel (curling fingers at the start of a swipe down read as Launchpad), exit speed = progress/s over the last 60 ms × 0.008 × 300.
- **Follow-Trackpad wins.** With Follow-Trackpad on (default), `InputPipeline.applyGestureSettings` lets trackpad prefs overwrite the menu value, including three-finger drag (off when the macOS key is absent). The stored menu value only applies when following is off.
- **Display identity lives in `TouchDisplayIdentity.sibolanFHD`** (vendor 20236, model 0, "SIBOLAN", 339.85x189.84 mm) — pipeline, self-test and Event Sink share it. Menu "Touch Display" picker persists vendor/model/nameHint in `StoredSettings`. Model 0 is weak; prefer name/serial where available.
- **Touch panel USB IDs:** `0x222A:0x0001` in `HIDTouchSource.swift`; report layout (report 4, 10×5-byte slots) in `ReportParser.swift`. Panel seized via `kIOHIDOptionsTypeSeizeDevice`.
- **Apple silicon; macOS 15 to 27.** Relies on private behavior: dock swipes (macOS 15-26: type-30/subtype-23 CGEvent fields + type-29 companion; macOS 27+: an IOHIDEvent attached with `SLEventSetIOHIDEvent` via `HIDEventBridge.attachDockSwipe`, no type-29 — the old fields are silently ignored there), event field 51 + `CGEventSetWindowLocation`, SkyLight/IOKit calls looked up at runtime. Missing SPI → that feature turns off (dock swipes fall back to the old format and log it).
- **`--dockswipe-selftest` can't detect Mission Control.** The Dock keeps a layer-20 window on the touch display, so a Dock-window check is always "open". Watch the screen.
- **The Launchpad pinch switch on macOS 27** didn't reach `TrackpadFourFingerPinchGesture` in `com.apple.AppleMultitouchTrackpad` when changed in System Settings (2026-11-04); setting the key with `defaults write` works. Where System Settings now stores it is not yet known.
- **Settings persistence:** `StoredSettings` (UserDefaults `com.theofanis.touchbridge`) persists all except Enabled/Dry-Run — including the picked display. Evidence: `docs/hardware/sibolan-fhd.md` + `sibolan-fhd-edid.bin`.

## Diagnostics (run on `build/TouchBridge.app`, not the installed copy)

```bash
./scripts/bundle.sh
open -n build/TouchBridge.app --args --probe 90            # † raw HID reports → ~/Library/Logs/TouchBridge/probe-*.jsonl
open -n build/TouchBridge.app --args --ax-probe --menubar  # read-only: displays, vendor/model, clocks, Dock
open -n build/TouchBridge.app --args --dry-run             # † recognize + log, send nothing
open -n build/TouchBridge.app --args --system-ui-selftest # VISIBLE: opens/closes NC + Launchpad
```

`†` needs the panel: quit installed copy first (✋ → Quit). Logs in `~/Library/Logs/TouchBridge/` (`touchbridge.log`, `eventsink.log`).
