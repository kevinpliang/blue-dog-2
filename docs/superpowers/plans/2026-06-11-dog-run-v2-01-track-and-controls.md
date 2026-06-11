# Dog Run V2 Phase 1: Infinite Track and Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide the track endpoint with a distance fade and improve mobile gesture reliability without changing the intentional duck timing.

**Architecture:** Add a lightweight spatial shader for distant track visuals and extract pointer interpretation into a pure `InputInterpreter`. `RunnerSimulation` receives buffered jump and duck commands while preserving current lane behavior and the locked `0.3s` duck plus `0.05s` post-duck cooldown.

**Tech Stack:** Godot 4, GDScript, Godot spatial shaders, headless GDScript tests

---

### Task 1: Lock current duck tuning with regression tests

**Files:**
- Modify: `tests/test_runner_simulation.gd`
- Verify: `game/runner_simulation.gd`

- [ ] **Step 1: Add an explicit locked-timing regression test**

Add:

```gdscript
func test_duck_timing_remains_intentional() -> void:
	expect_equal(Simulation.DUCK_DURATION, 0.3, "duck duration remains intentional")
	expect_equal(Simulation.DUCK_COOLDOWN, 0.05, "duck cooldown remains intentional")
```

Call it from `run_all()`.

- [ ] **Step 2: Run the simulation suite**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
```

Expected: `Dog Run simulation tests passed.`

- [ ] **Step 3: Commit**

```powershell
git add tests/test_runner_simulation.gd
git commit -m "test: lock intentional duck timing"
```

### Task 2: Add a pure viewport-normalized input interpreter

**Files:**
- Create: `game/input_interpreter.gd`
- Create: `tests/test_input_interpreter.gd`
- Modify: `tests/test_runner.gd`
- Modify: `game/main.gd`

- [ ] **Step 1: Write failing input interpreter tests**

Create `tests/test_input_interpreter.gd` covering:

```gdscript
func test_short_pointer_release_is_tap() -> void:
	var input = InputInterpreter.new()
	assert_equal(input.interpret(Vector2.ZERO, Vector2(20, 10), Vector2(720, 1280)), InputInterpreter.Command.TAP)

func test_threshold_scales_with_viewport_width() -> void:
	var input = InputInterpreter.new()
	assert_equal(input.interpret(Vector2.ZERO, Vector2(60, 0), Vector2(720, 1280)), InputInterpreter.Command.RIGHT)
	assert_equal(input.interpret(Vector2.ZERO, Vector2(60, 0), Vector2(1440, 2560)), InputInterpreter.Command.TAP)

func test_dominant_axis_selects_direction() -> void:
	var input = InputInterpreter.new()
	assert_equal(input.interpret(Vector2.ZERO, Vector2(-80, 30), Vector2(720, 1280)), InputInterpreter.Command.LEFT)
	assert_equal(input.interpret(Vector2.ZERO, Vector2(20, -100), Vector2(720, 1280)), InputInterpreter.Command.JUMP)
	assert_equal(input.interpret(Vector2.ZERO, Vector2(20, 100), Vector2(720, 1280)), InputInterpreter.Command.DUCK)
```

Update `tests/test_runner.gd` to run both suites and aggregate failures.

- [ ] **Step 2: Run tests and verify RED**

Run the headless test command. Expected: failure because `input_interpreter.gd` does not exist.

- [ ] **Step 3: Implement minimal interpreter**

Create `InputInterpreter` with:

```gdscript
class_name InputInterpreter
extends RefCounted

enum Command { TAP, LEFT, RIGHT, JUMP, DUCK }

const SWIPE_WIDTH_RATIO := 50.0 / 720.0

func interpret(start: Vector2, finish: Vector2, viewport_size: Vector2) -> Command:
	var swipe := finish - start
	var threshold := viewport_size.x * SWIPE_WIDTH_RATIO
	if swipe.length() < threshold:
		return Command.TAP
	if absf(swipe.x) > absf(swipe.y):
		return Command.RIGHT if swipe.x > 0.0 else Command.LEFT
	return Command.DUCK if swipe.y > 0.0 else Command.JUMP
```

Replace `_handle_pointer_release()` branching in `game/main.gd` with `InputInterpreter.interpret(...)` and command dispatch.

- [ ] **Step 4: Run tests and verify GREEN**

Run the headless test command. Expected: all suites pass.

- [ ] **Step 5: Commit**

```powershell
git add game/input_interpreter.gd game/main.gd tests/test_input_interpreter.gd tests/test_runner.gd
git commit -m "feat: normalize mobile swipe interpretation"
```

### Task 3: Add jump and duck input buffering

**Files:**
- Modify: `game/runner_simulation.gd`
- Modify: `tests/test_runner_simulation.gd`

- [ ] **Step 1: Write failing buffer tests**

Add tests proving:

```gdscript
func test_early_jump_runs_on_landing() -> void:
	var simulation = airborne_simulation_near_landing()
	simulation.jump()
	simulation.step(0.1)
	expect_true(simulation.vertical_velocity > 0.0, "buffered jump runs on landing")

func test_early_duck_runs_after_cooldown() -> void:
	var simulation = Simulation.new()
	simulation.start(42)
	clear_obstacles(simulation)
	simulation.duck()
	simulation.step(Simulation.DUCK_DURATION)
	simulation.duck()
	simulation.step(Simulation.DUCK_COOLDOWN + 0.01)
	expect_true(simulation.duck_time > 0.0, "buffered duck runs after cooldown")
```

Use a `0.12s` input buffer and keep `DUCK_DURATION == 0.3` and `DUCK_COOLDOWN == 0.05`.

- [ ] **Step 2: Run tests and verify RED**

Expected: buffered actions do not execute.

- [ ] **Step 3: Implement minimal buffers**

Add:

```gdscript
const INPUT_BUFFER_DURATION := 0.12
var jump_buffer_time := 0.0
var duck_buffer_time := 0.0
```

When an action cannot currently run, set its buffer. During `step()`, decrement buffers and execute as soon as action preconditions become true. Clear buffers on `start()`.

- [ ] **Step 4: Run tests and verify GREEN**

Expected: simulation suite passes, including locked duck-timing regression.

- [ ] **Step 5: Commit**

```powershell
git add game/runner_simulation.gd tests/test_runner_simulation.gd
git commit -m "feat: buffer jump and duck input"
```

### Task 4: Fade the track into the distance

**Files:**
- Create: `game/shaders/distance_fade.gdshader`
- Modify: `game/main.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Add a failing scene smoke assertion**

Assert that nodes named `Track`, `LaneDividerLeft`, `LaneDividerRight`, `TrackEdgeLeft`, and `TrackEdgeRight` use materials whose shaders are `distance_fade.gdshader`.

- [ ] **Step 2: Run smoke test and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: failure because track nodes are unnamed and use `StandardMaterial3D`.

- [ ] **Step 3: Create the distance shader**

Create:

```glsl
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform float fade_start = 70.0;
uniform float fade_end = 145.0;

void fragment() {
	float distance_from_camera = length(VERTEX);
	float visibility = 1.0 - smoothstep(fade_start, fade_end, distance_from_camera);
	ALBEDO = base_color.rgb * visibility;
}
```

Use a `ShaderMaterial` helper in `main.gd`, extend track geometry to approximately `220m` with its far endpoint beyond `fade_end`, name the five track nodes, and apply the fade shader. Set line `base_color` to cyan and track `base_color` to dark blue-black.

- [ ] **Step 4: Run smoke test and render verification**

Run the smoke test, then capture:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --path . --resolution 405x720 --write-movie "$env:TEMP\dog-run-v2-track.png" --fixed-fps 30 --quit-after 2
```

Expected: no hard track endpoint is visible; track and cyan lines fade into black.

- [ ] **Step 5: Commit**

```powershell
git add game/shaders/distance_fade.gdshader game/main.gd tests/test_main_smoke.gd
git commit -m "feat: fade track into distance"
```

### Task 5: Respect mobile safe areas

**Files:**
- Modify: `game/main.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Add a failing safe-area smoke assertion**

Require a named `HudSafeArea` `MarginContainer` as the parent of score, best-score, and overlay controls.

- [ ] **Step 2: Run smoke test and verify RED**

Expected: `HudSafeArea` is missing.

- [ ] **Step 3: Build HUD inside a safe-area container**

Create `HudSafeArea`, read `DisplayServer.get_display_safe_area()` where available, convert the safe rectangle into container margins, and fall back to the current `24px` inset on desktop.

- [ ] **Step 4: Verify**

Run simulation tests, scene smoke test, and headless startup.

- [ ] **Step 5: Manual checkpoint**

On one portrait Android or iOS device, verify score and best score do not overlap notches, status bars, or rounded corners.

- [ ] **Step 6: Commit**

```powershell
git add game/main.gd tests/test_main_smoke.gd
git commit -m "feat: respect mobile safe areas"
```
