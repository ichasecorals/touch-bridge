# Changelog

## Unreleased

- Touch display is now the SIBOLAN FHD (EDID vendor 20236, model 0, 339.85 × 189.84 mm); `TouchDisplayIdentity` is the single source of truth for the pipeline, self-test and Event Sink, with a Touch Display picker in the menu.
- Four-finger system gestures work with three-finger drag off (finger counting decoupled from drag handling); three-finger touch still scrolls when drag is off.
- Gesture thresholds use the SIBOLAN physical size (or the picked display's), not a fixed panel size.
- **Mission Control, Spaces and Launchpad work on macOS 27.** macOS 27 no longer reads the CGEvent fields the dock swipes were built from; on macOS 27 the swipe now travels as an attached IOHIDEvent (DockSwipe type, motion, flavor and progress, plus a Velocity child on release), as in Mac Mouse Fix commit f92d2d53a. Older macOS keeps the old format.
- Four-finger swipes are more reliable on a touchscreen:
  - one finger lifting early (or the panel dropping a contact) no longer ends the swipe while three fingers are still down;
  - the same finger travel counts for twice the progress (40 mm per unit instead of 80), so 1-2 cm swipes complete;
  - the exit speed is the average over the last 60 ms, not the last frame, so a swipe that slows before lifting still counts;
  - a four-finger pinch needs 10 mm of spread change and twice the hand's travel, so fingers drifting together during a swipe up aren't read as Launchpad.
- With the Launchpad & Show Desktop pinch switched off, four-finger movements are judged only as swipes.
- Fixes: tap count stops at 3; the log rotates at about 5 MB without losing the line that triggered it; the self-test uses the picked display, and `--dockswipe-selftest` no longer opens Mission Control itself (its Dock-window check was always true, so the test looked like it passed when nothing happened).
- Each dock swipe logs one line when it begins and one when it ends (steps, progress, exit speed).
- **Scrolling feels like the Magic Trackpad**, measured from the owner's trackpad with the Event Sink:
  - the glide after lifting runs at 60 Hz, keeps 94 % of its speed per step and starts at 1.3 × the release speed, so a flick coasts about a second (it used to stop after about half a second);
  - trackpad-style acceleration: slow movement follows the fingers one to one, fast movement moves the content up to twice as far; the glide starts from that speed.
- The Event Sink logs each scroll event's timestamp and, for finger scrolls, the HID event the trackpad attaches (its accelerated travel), for measuring scroll behaviour.

## 1.1.0 (2026-10-11)

- **Touch Mode menu** (✋ → Touch Mode). It resets to Gestures at each start, and the menu-bar icon shows a special mode.
  - **Drawing** (✏️): the first finger is a pen, from touch-down to lift. Every other finger, a resting palm and every gesture are ignored. Strokes go through the window server, so drawing apps and websites see a real mouse press.
  - **Multitouch Apps** (🖐): every finger, up to ten, as TUIO 1.1 over UDP to `127.0.0.1:3333`, for TUIO apps such as TouchDesigner, Processing, openFrameworks, Unity, Max or Kivy. Nothing is delivered to macOS in this mode.
- **Event Sink as a multitouch test canvas:** it reads TUIO and paints every finger in its own colour, plus the mouse stroke in grey, with a live finger count and a Clear button.
- The README explains what macOS allows: ordinary apps, web pages and iPhone/iPad apps get a single pointer, so more fingers reach only apps that read a multitouch protocol such as TUIO.

## 1.0.0 (2026-10-11)

The first stable release. On the tested setup (an ARZOPA touch monitor with an ILITEK controller, macOS 15), the touch display behaves like a touchscreen with a trackpad built in:

- Touches land on the touch display, and for most gestures the cursor stays where it is.
- **Gestures:**
  - tap, double and triple tap, right-click (hold);
  - scrolling with momentum, pinch, rotate;
  - click-and-drag, three-finger drag, window moves by the title bar.
- **The trackpad's system gestures with the system's own animations**, opening on the touch display: Mission Control, App Exposé, Spaces, Launchpad, Show Desktop and Notification Center.
- **Back/forward page swipes** that follow your fingers, in Safari and other apps with trackpad page swipes.
- **Follows the trackpad settings** in System Settings.
- **Daily reliability:**
  - starts at login and restarts after a crash;
  - recovers after replug and sleep;
  - crash-safe mouse presses.
- README for newcomers, MIT license. The replay recording now ships with the repo, so a fresh clone runs all tests.

No functional changes since 0.6.4.

## 0.6.4

- The menu lists the followed trackpad settings one per line, instead of one long line that made the menu too wide.

## 0.6.3

- **Crash-safe press recovery.** The press journal records where a press was made and, for presses sent straight to an app, the window and the app. After a crash, the restarted app releases the press there:
  - an interrupted drag drops back where it started;
  - a reused process ID never receives the release.

## 0.6.2

- **Real trackpad page swipes.** Two-finger scrolls now carry the scroll-gesture stream a real trackpad sends: type-29 gesture events, subtype 61, then 6 for each movement, then 62. AppKit's swipe tracking measures progress from that stream, so Safari's back/forward swipe follows the fingers and completes or snaps back natively.
- The stream was found by tapping all events sent to a test window's process, because the swipe tracker takes them before any app-level monitor sees them.
- 0.6.0 and 0.6.1 were prototypes: a quick flick sent ⌘[ / ⌘], then pressed the app's Back/Forward menu item instead. Both were replaced by the real swipe.

## 0.5.10

- **Three-finger drag, "rest a finger, add two".** Rest one finger on an item, add two more within 1.5 s, and move. The drag grabs exactly where the resting finger first touched.

## 0.5.8

- A Space switch on the touch display follows the hidden cursor alone; the earlier step of focusing a window first was removed.
- **Keep Focus When Switching Spaces** (on by default) gives focus back to the app on the other screen after a Space switch by touch.

## 0.5.5

- **System gestures with the system's own animations**, via synthesized dock-swipe events:
  - four fingers up / down: Mission Control / App Exposé;
  - four fingers left / right: switch Space;
  - thumb pinch / spread: Launchpad / Show Desktop.
- Two fingers from the right edge open Notification Center.
- **All of them open on the touch display:**
  - Notification Center and Spaces follow the cursor, so the hidden cursor waits on the touch display while they open;
  - Launchpad follows the Dock, so the Dock is brought over first.
- Menu "Launchpad on the Touch Display" chooses whether the Dock comes over, comes over then goes back, or stays put.
- Diagnostics: `--dockswipe-selftest`, `--ax-probe --menubar`, `--system-ui-selftest`.

## 0.4.0

- **Follows the trackpad settings** in System Settings → Trackpad: three-finger drag, scrolling, momentum, pinch and rotate. Changes are picked up within seconds and after wake. A "Follow Trackpad Settings" master switch controls this.

## 0.3.0

- **Three-finger drag**, like the trackpad setting, grabbing at the centre of the fingers or under the first finger.
- Menu settings survive restarts.

## 0.2.0

- **Start at Login**: a per-user launch agent that starts TouchBridge at login and restarts it after a crash.
- `scripts/install.sh` installs and updates the copy in `~/Applications`.
- **Multitouch after replug and sleep.** The panel then starts in single-touch "mouse" mode; TouchBridge reads its feature reports to switch it back, as Linux's hid-multitouch driver does.

## 0.1.0

- **First version.** A user-space driver that seizes the touch panel and delivers touches to the touch display without moving the cursor.
- **Delivery:**
  - Direct: events posted to the app under the finger with window addressing, and the app activated before clicks;
  - Warp: a fallback for window moves, the Dock and menu bar, pop-up menus and Chromium apps.
- **Gestures:** tap, double and triple tap, right-click, scrolling with momentum, pinch, rotate, click-and-drag, window moves.
- Menu-bar agent with diagnostics.
