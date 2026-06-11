# Wall Row Spacing Design

## Goal

Give players more reaction time inside wall-heavy obstacle clusters while preserving the natural difficulty increase caused by runner speed.

## Rule

Consecutive rows that both contain at least one wall must be separated by at least `8.0` meters.

The spacing is fixed rather than speed-aware. At higher speeds, the same physical distance therefore provides less reaction time and keeps later runs more challenging.

## Scope

The rule applies only within curated multi-row patterns. Existing gaps between separate patterns already exceed `8.0` meters.

Rows involving ground blocks or overhead bars keep their current offsets unless both adjacent rows also contain walls. Runner speed, lane-change speed, action timing, generation order, and pattern selection remain unchanged.

## Implementation

`PatternLibrary` exposes the minimum as `MIN_CONSECUTIVE_WALL_ROW_SPACING`. Wall-heavy pattern offsets are updated to satisfy it:

- Two-row wall patterns use offsets `0.0`, `8.0`.
- Three-row wall patterns use offsets `0.0`, `8.0`, `16.0`.

Pattern-library tests inspect all curated patterns and reject any consecutive wall rows below the minimum.

