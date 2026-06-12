# Early Pattern Spacing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce obstacle frequency at the beginning of a run with a tunable pattern-gap curve that returns to the existing spacing by `250m`.

**Architecture:** Keep curated pattern rows, selection, and spawning unchanged. Move the hard-coded inter-pattern spacing values into `RunnerTuning`, then make `RunnerSimulation._row_spacing()` interpolate from the early gap to the existing speed-based gap using run distance.

**Tech Stack:** Godot 4.5, GDScript, existing headless GDScript test suites

---

### Task 1: Add Tunable Pattern Spacing

**Files:**
- Modify: `tests/test_runner_tuning.gd`
- Modify: `game/runner_tuning.gd`
- Modify: `game/default_runner_tuning.tres`

- [ ] **Step 1: Write the failing tuning assertions**

Add these assertions after the speed properties in `tests/test_runner_tuning.gd`:

```gdscript
expect_property_equal(TUNING, "early_pattern_spacing", 18.0, "early patterns begin farther apart")
expect_property_equal(TUNING, "early_spacing_end_distance", 250.0, "early spacing reaches normal at tier one")
expect_property_equal(TUNING, "normal_pattern_spacing_base", 15.0, "normal spacing preserves its base")
expect_property_equal(TUNING, "normal_pattern_spacing_speed_factor", 0.25, "normal spacing preserves speed scaling")
expect_property_equal(TUNING, "minimum_pattern_spacing", 9.0, "pattern spacing preserves its minimum")
```

- [ ] **Step 2: Run the focused tuning suite and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_tuning.gd
```

Expected: FAIL with missing-property messages for the five new spacing properties.

- [ ] **Step 3: Add the tuning properties**

Add these properties after the speed properties in `game/runner_tuning.gd`:

```gdscript
@export var early_pattern_spacing := 18.0
@export var early_spacing_end_distance := 250.0
@export var normal_pattern_spacing_base := 15.0
@export var normal_pattern_spacing_speed_factor := 0.25
@export var minimum_pattern_spacing := 9.0
```

Add the explicit values in `game/default_runner_tuning.tres` so they are easy to edit:

```text
early_pattern_spacing = 18.0
early_spacing_end_distance = 250.0
normal_pattern_spacing_base = 15.0
normal_pattern_spacing_speed_factor = 0.25
minimum_pattern_spacing = 9.0
```

- [ ] **Step 4: Run the focused tuning suite and verify GREEN**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_tuning.gd
```

Expected: exit code `0` with no failure output.

- [ ] **Step 5: Commit the tuning slice**

```powershell
git add tests/test_runner_tuning.gd game/runner_tuning.gd game/default_runner_tuning.tres
git commit -m "feat: add pattern spacing tuning"
```

### Task 2: Implement the Early Spacing Curve

**Files:**
- Modify: `tests/test_runner_simulation.gd`
- Modify: `game/runner_simulation.gd`

- [ ] **Step 1: Add the spacing test to the simulation suite**

Add this call after `test_speed_caps_and_score_tracks_distance()` in `run_all()`:

```gdscript
test_pattern_spacing_eases_into_normal_frequency()
```

Add this test function before `test_seeded_generation_is_deterministic_and_fair()`:

```gdscript
func test_pattern_spacing_eases_into_normal_frequency() -> void:
	var simulation = Simulation.new()
	simulation.speed = simulation.TUNING.start_speed

	simulation.distance = 0.0
	expect_float_equal(simulation._row_spacing(), 18.0, "run starts with wider pattern spacing")

	simulation.distance = simulation.TUNING.early_spacing_end_distance * 0.5
	expect_float_equal(simulation._row_spacing(), 15.0, "early pattern spacing transitions smoothly")

	simulation.distance = simulation.TUNING.early_spacing_end_distance
	expect_float_equal(simulation._row_spacing(), 12.0, "tier one uses the normal speed-based spacing")

	simulation.distance = simulation.TUNING.early_spacing_end_distance * 2.0
	simulation.speed = simulation.TUNING.max_speed
	expect_float_equal(simulation._row_spacing(), 9.0, "normal spacing preserves its minimum")
```

Add this helper beside the existing assertion helpers:

```gdscript
func expect_float_equal(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
```

- [ ] **Step 2: Run the focused simulation suite and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_simulation.gd
```

Expected: FAIL because the current hard-coded formula returns `12m` instead of `18m` at the start and does not ease by distance.

- [ ] **Step 3: Replace the hard-coded spacing formula**

Replace `_row_spacing()` in `game/runner_simulation.gd` with:

```gdscript
func _row_spacing() -> float:
	var normal_spacing := maxf(
		TUNING.minimum_pattern_spacing,
		TUNING.normal_pattern_spacing_base - speed * TUNING.normal_pattern_spacing_speed_factor
	)
	var early_ratio := clampf(
		distance / maxf(TUNING.early_spacing_end_distance, 0.001),
		0.0,
		1.0
	)
	return lerpf(TUNING.early_pattern_spacing, normal_spacing, early_ratio)
```

This function is only called after a complete curated pattern is spawned, so internal row offsets remain unchanged.

- [ ] **Step 4: Run the focused simulation suite and verify GREEN**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_simulation.gd
```

Expected: exit code `0` with no failure output.

- [ ] **Step 5: Run all automated regressions**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_mobile_tap.gd
```

Expected:

```text
Dog Run simulation tests passed.
Dog Run active scene smoke test passed.
Dog Run mobile tap test passed.
```

- [ ] **Step 6: Review scope and commit**

Run:

```powershell
git diff --check
git status --short
```

Expected: no whitespace errors and only the intended simulation/test changes.

Commit:

```powershell
git add tests/test_runner_simulation.gd game/runner_simulation.gd
git commit -m "feat: ease early obstacle frequency"
```
