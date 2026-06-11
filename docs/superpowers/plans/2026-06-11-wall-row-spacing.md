# Wall Row Spacing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Guarantee an `8m` minimum between consecutive wall-containing rows without changing other obstacle timing.

**Architecture:** Keep spacing authored in the data-only `PatternLibrary`. Add one named spacing constant and enforce it with a pattern-library regression test.

**Tech Stack:** Godot 4.5, GDScript, headless GDScript tests

---

### Task 1: Enforce Wall Row Spacing

**Files:**
- Modify: `tests/test_pattern_library.gd`
- Modify: `game/pattern_library.gd`

- [x] **Step 1: Add a failing pattern-library regression test**

Inspect every adjacent row pair. When both rows contain a wall, assert their offset difference is at least `PatternLibrary.MIN_CONSECUTIVE_WALL_ROW_SPACING`.

- [x] **Step 2: Run the full simulation suite and verify RED**

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
```

Expected: the named minimum is missing or existing `5m` wall gaps violate it.

- [x] **Step 3: Add the minimum and update wall-heavy patterns**

Add:

```gdscript
const MIN_CONSECUTIVE_WALL_ROW_SPACING := 8.0
```

Change two-row wall patterns from `0, 5` to `0, 8`, and three-row wall patterns from `0, 5, 10` to `0, 8, 16`.

- [x] **Step 4: Run all automated tests**

Run the simulation suite, active-scene smoke test, and mobile-tap regression.

- [x] **Step 5: Review generated pattern spacing**

Confirm wall-heavy rows meet the fixed minimum, mixed jump/duck patterns retain their existing offsets, and simulation constants remain untouched.
