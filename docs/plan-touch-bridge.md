# TouchBridge — Issues & Fixes Plan

Saved: 2026-11-04. Verified against codebase + `Monitor/` EDID + `swift test` (152 passed on Xcode 27.2).
Tick off each `[ ]` as it is completed.

## Phase 0 — Ground truth (no code)

- [x] Canonical display confirmed: vendor `20236` (SXL `0x4F0C`), model `0`, name `SIBOLAN FHD`, serial `8R33926O00QS`, size **339.85 × 189.84 mm**, 1920×1080 native.
- [x] Decided: match by vendor/model only, or by name/serial too (model `0` is weak — check for other SXL panels).

## Phase 1 — Four-finger gestures dead when three-finger drag is off (HIGH)

- [x] Promotion 1→2→3→4 decoupled from `threeFingerDrag` in `GestureRecognizer.swift` (only `.dragBegan` checks it).
- [x] Defaults reconciled: `PipelineSettings=true` vs `TrackpadPreferences=false` vs `StoredSettings.trackpadThreeFingerDrag()=true` — one rule documented.
- [x] Regression tests added: 4-finger vertical + horizontal with `threeFingerDrag=false`.
- [x] Verified: `swift test --filter GestureRecognizerTests` passes + standalone 4-finger repro.

## Phase 2 — Finish SIBOLAN migration (HIGH)

- [x] Single source of truth (`TouchDisplayIdentity`) wired through pipeline + `SystemUISelfTest` + `EventSink`.
- [x] `SystemUISelfTest.swift:15` no longer hardcodes `7908/342`.
- [x] `EventSink.swift:16` no longer matches `"ARZOPA"`; `NSScreen.main!` fallback replaced with loud failure.
- [x] `panelWidthMm/HeightMm` updated `309.3/173.9 → 339.9/189.8`; tap slop / edge-zone re-checked.
- [x] Pipeline fails loudly (menu warning + log) when no display matches.
- [x] Display picker from `DisplayLocator.onlineDisplays()` added; choice persisted in `StoredSettings`.
- [x] Docs updated in same commit: README hardware table, CHANGELOG entry, Info.plist string, `spec.md:22`, `InputPipeline.swift:11` + `MenuBarApp.swift:13` comments.
- [x] `Monitor/` hygiene done: renamed to `sibolan-fhd-edid.bin` (no spaces), moved to `docs/hardware/` + summary note, 11 KB dump deleted.
- [ ] Verified live: `--ax-probe --menubar`, `--system-ui-selftest`, Event Sink on touch display (needs running app + display).

## Phase 3 — Toolchain docs (MEDIUM)

- [x] README fixed: build = CLT OK, test = Xcode required; CI image matched.
- [x] Verified: `swift test` runs on clean checkout (152 → 154 tests green on Xcode 27.2).

## Phase 4 — Correctness & hygiene (MEDIUM/LOW)

- [x] `InputPipeline.swift:436` `@Sendable` capture of `done` fixed (`@Sendable` on both `pushDock`/`pushDockStep`).
- [x] 5× `ImplicitStrongCapture` in `MenuBarApp.swift:49,53,79,207,210` fixed (outer `[weak self]` to match inner).
- [x] Stale comments updated: `onContacts`, `TrackpadPreferences`.
- [x] Minor fixes: tap count capped at 3; `DirectTarget` zero-size rect documented (size unused by design); log rotation cap (~5 MB + `-old.log`) in `FileLog`.
- [x] Latency reviewed: window-drag answer memoized per gesture (`windowDragMemo`), journal writes are small appends; no change — measure on hardware if drags feel sticky.
- [x] Verified: `swift build` warning-free, `swift test` green (154/154).

## Suggested order

Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4.
