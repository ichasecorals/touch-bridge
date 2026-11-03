# SIBOLAN FHD — display evidence

Source: BetterDisplay 5.1.1 report + 256-byte EDID (`sibolan-fhd-edid.bin`,
EDID 1.4 + CEA extension), captured 2026-11-03 on the M4 Mac.

- Name: **SIBOLAN FHD** · vendor **20236** (SXL `0x4F0C`) · model **0** · serial `8R33926O00QS`
- EDID serial field is 0; the ASCII descriptor carries the serial. Model 0 is a
  weak key — prefer name/serial where available.
- Native **1920×1080**, 60 Hz, DisplayPort HBR2, 10 bpc; HiDPI 1920 logical →
  3840×2160 pixels on this Mac.
- Physical active area: **339.85 × 189.84 mm** (EDID: 34×19 cm) → gesture
  thresholds in `GestureConfig` use `panelWidthMm = 339.85`.
- `CGDirectDisplayID: 2`, UUID `24E499FE-48EE-4747-9006-F60428F21A77` (machine-specific).

The full BetterDisplay dump was reduced to this note; the EDID binary is the
machine-readable ground truth.
