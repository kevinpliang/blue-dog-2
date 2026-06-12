# Airborne Duck Roll Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make ducking during a jump immediately enter a compact fast dive, then transition into the existing short ground roll.

**Architecture:** Add a separate `air_duck_time` state to `RunnerSimulation` so airborne descent and grounded duck timing remain independent. The simulation owns input rules, descent timing, collision state, and events; `Main` only reads the new state to apply the compact airborne-roll pose.

**Tech Stack:** Godot 4.5, GDScript, existing headless GDScript test suites

---

### Task 1: Add Airborne-Duck Tuning

**Files:**
- Modify: `tests/test_runner_tuning.gd`
- Modify: `game/runner_tuning.gd`
- Modify: `game/default_runner_tuning.tres`

- [ ] **Step 1: Write the failing tuning test**

Add this assertion after the existing duck cooldown assertion in `tests/test_runner_tuning.gd`:

```gdscript
expect_property_equal(TUNING, "air_duck_dive_duration", 0.12, "airborne duck dive stays brief")
```

- [ ] **Step 2: Run the focused tuning suite and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_tuning.gd
```

Expected: FAIL with `missing property air_duck_dive_duration`.

- [ ] **Step 3: Add the tuning property**

Add the property beside the existing duck timing properties in `game/runner_tuning.gd`:

```gdscript
@export var duck_duration := 0.3
@export var duck_cooldown := 0.05
@export var air_duck_dive_duration := 0.12
```

Set the explicit default in `game/default_runner_tuning.tres`:

```text
[resource]
script = ExtResource("1_tuning")
air_duck_dive_duration = 0.12
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
git commit -m "feat: add airborne duck timing"
```

### Task 2: Implement Airborne-Duck Simulation Rules

**Files:**
- Modify: `tests/test_runner_simulation.gd`
- Modify: `game/runner_simulation.gd`

- [ ] **Step 1: Replace the obsolete airborne-duck assertion**

In `test_jump_and_duck_rules()`, replace:

```gdscript
jumping.duck()
expect_equal(jumping.duck_time, 0.0, "duck is ignored while airborne")
```

with:

```gdscript
jumping.duck()
expect_true(jumping.is_air_ducking(), "duck starts a fast dive while airborne")
expect_true(jumping.is_ducking(), "airborne duck immediately activates duck collision")
```

- [ ] **Step 2: Add failing fast-dive, transition, input, and event tests**

Add these calls to `run_all()` after `test_jump_and_duck_rules()`:

```gdscript
test_airborne_duck_dives_and_transitions_to_roll()
test_airborne_duck_uses_duck_collision_rules()
test_airborne_duck_blocks_jump_but_allows_lane_changes()
```

Add these test functions:

```gdscript
func test_airborne_duck_dives_and_transitions_to_roll() -> void:
	var simulation = Simulation.new()
	simulation.start(34)
	clear_obstacles(simulation)
	simulation.jump()
	simulation.step(0.1)
	var starting_height: float = simulation.player_y

	simulation.duck()
	var events := simulation.drain_events()
	expect_true(simulation.is_air_ducking(), "airborne duck starts a dive")
	expect_true(simulation.is_ducking(), "dive protects against overhead bars immediately")
	expect_true(has_event(events, "air_duck_started"), "airborne duck emits its start event")

	simulation.step(simulation.TUNING.air_duck_dive_duration * 0.5)
	expect_true(simulation.player_y < starting_height and simulation.player_y > 0.0, "dive descends smoothly before landing")

	simulation.step(simulation.TUNING.air_duck_dive_duration * 0.5 + 0.001)
	expect_true(simulation.is_grounded(), "dive reaches the ground in the tuned duration")
	expect_true(not simulation.is_air_ducking(), "airborne dive ends on landing")
	expect_true(simulation.duck_time > 0.0, "landing begins the normal ground roll")


func test_airborne_duck_blocks_jump_but_allows_lane_changes() -> void:
	var simulation = Simulation.new()
	simulation.start(35)
	clear_obstacles(simulation)
	simulation.jump()
	simulation.duck()
	var dive_time: float = simulation.air_duck_time

	simulation.jump()
	simulation.duck()
	simulation.change_lane(1)
	expect_equal(simulation.jump_buffer_time, 0.0, "jump is not buffered during the dive")
	expect_equal(simulation.air_duck_time, dive_time, "repeated duck does not restart the dive")
	expect_equal(simulation.target_lane, 2, "lane changes remain available during the dive")

	simulation.step(simulation.TUNING.air_duck_dive_duration + 0.001)
	var roll_time: float = simulation.duck_time
	simulation.jump()
	simulation.duck()
	expect_equal(simulation.jump_buffer_time, 0.0, "jump is not buffered during the landing roll")
	expect_equal(simulation.vertical_velocity, 0.0, "landing roll does not immediately jump")
	expect_equal(simulation.duck_time, roll_time, "repeated duck does not restart the landing roll")


func test_airborne_duck_uses_duck_collision_rules() -> void:
	var overhead = Simulation.new()
	overhead.start(36)
	clear_obstacles(overhead)
	overhead.player_y = 0.5
	overhead.vertical_velocity = 1.0
	overhead.duck()
	overhead.obstacles.append({
		"id": 900,
		"row_id": 900,
		"lane": overhead.target_lane,
		"type": Simulation.ObstacleType.OVERHEAD_BAR,
		"z": -0.1,
	})
	overhead.step(0.01)
	expect_equal(overhead.state, Simulation.RunState.RUNNING, "airborne duck clears an overhead bar immediately")

	var ground = Simulation.new()
	ground.start(37)
	clear_obstacles(ground)
	ground.player_y = 0.5
	ground.vertical_velocity = 1.0
	ground.duck()
	ground.obstacles.append({
		"id": 901,
		"row_id": 901,
		"lane": ground.target_lane,
		"type": Simulation.ObstacleType.GROUND_BLOCK,
		"z": -0.1,
	})
	ground.step(0.01)
	expect_equal(ground.state, Simulation.RunState.IMPACT, "airborne duck still collides with a low ground block")
```

- [ ] **Step 3: Run the focused simulation suite and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_simulation.gd
```

Expected: FAIL because `is_air_ducking()` and `is_ducking()` do not exist and airborne duck is still buffered.

- [ ] **Step 4: Add and reset airborne-duck state**

Add beside the existing duck state:

```gdscript
var duck_time := 0.0
var duck_cooldown_time := 0.0
var air_duck_time := 0.0
```

Reset it in `start()`:

```gdscript
duck_time = 0.0
duck_cooldown_time = 0.0
air_duck_time = 0.0
```

- [ ] **Step 5: Implement committed input rules**

Replace `jump()`, `duck()`, and the duck-start helpers with:

```gdscript
func jump() -> void:
	if state != RunState.RUNNING:
		return
	if is_air_ducking() or duck_time > 0.0:
		return
	if not is_grounded():
		jump_buffer_time = TUNING.input_buffer_duration
		return
	_start_jump()


func duck() -> void:
	if state != RunState.RUNNING or is_air_ducking() or duck_time > 0.0:
		return
	if not is_grounded():
		_start_air_duck()
		return
	if duck_cooldown_time > 0.0:
		duck_buffer_time = TUNING.input_buffer_duration
		return
	_start_duck()


func _start_air_duck() -> void:
	jump_buffer_time = 0.0
	duck_buffer_time = 0.0
	air_duck_time = maxf(TUNING.air_duck_dive_duration, 0.001)
	_emit_event("air_duck_started")


func _start_duck() -> void:
	duck_buffer_time = 0.0
	duck_time = TUNING.duck_duration
	duck_cooldown_time = TUNING.duck_duration + TUNING.duck_cooldown
	_emit_event("ducked")
```

Add the state queries beside `is_grounded()`:

```gdscript
func is_air_ducking() -> bool:
	return air_duck_time > 0.0


func is_ducking() -> bool:
	return is_air_ducking() or duck_time > 0.0
```

- [ ] **Step 6: Implement the timed descent and landing transition**

At the start of the running portion of `step()`, preserve whether the frame began in an airborne duck:

```gdscript
var was_grounded := is_grounded()
var was_air_ducking := is_air_ducking()
_update_vertical_motion(delta)
var landed := not was_grounded and is_grounded()
if landed:
	_emit_event("landed")
duck_time = maxf(0.0, duck_time - delta)
duck_cooldown_time = maxf(0.0, duck_cooldown_time - delta)
jump_buffer_time = maxf(0.0, jump_buffer_time - delta)
duck_buffer_time = maxf(0.0, duck_buffer_time - delta)
_apply_input_buffers()
if landed and was_air_ducking:
	_start_duck()
```

Replace `_update_vertical_motion()` with:

```gdscript
func _update_vertical_motion(delta: float) -> void:
	if is_air_ducking():
		var remaining := maxf(air_duck_time, 0.001)
		player_y = move_toward(player_y, 0.0, player_y * delta / remaining)
		air_duck_time = maxf(0.0, air_duck_time - delta)
		if air_duck_time <= 0.0 or player_y <= 0.001:
			player_y = 0.0
			vertical_velocity = 0.0
			air_duck_time = 0.0
		return

	if is_grounded():
		player_y = 0.0
		vertical_velocity = 0.0
		return

	vertical_velocity -= TUNING.gravity * delta
	player_y += vertical_velocity * delta
	if player_y <= 0.0:
		player_y = 0.0
		vertical_velocity = 0.0
```

Change the overhead-bar collision condition in `_has_collision()`:

```gdscript
ObstacleType.OVERHEAD_BAR:
	if not is_ducking():
		return true
```

- [ ] **Step 7: Run the focused simulation suite and verify GREEN**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/run_suite.gd -- res://tests/test_runner_simulation.gd
```

Expected: exit code `0` with no failure output.

- [ ] **Step 8: Commit the simulation slice**

```powershell
git add tests/test_runner_simulation.gd game/runner_simulation.gd
git commit -m "feat: add airborne duck roll"
```

### Task 3: Add the Compact Airborne-Roll Visual

**Files:**
- Modify: `tests/test_main_smoke.gd`
- Modify: `game/main.gd`

- [ ] **Step 1: Write the failing active-scene smoke check**

Add this condition after the existing movement-feedback condition in `_process()`:

```gdscript
elif not _uses_airborne_duck_visual():
	push_error("Main scene does not show the compact airborne duck roll.")
	quit(1)
```

Add this helper before `_uses_first_launch_tutorial()`:

```gdscript
func _uses_airborne_duck_visual() -> bool:
	var pivot: Node3D = _main.find_child("PlayerVisualPivot", true, false)
	if pivot == null:
		return false
	_main.simulation.player_y = 1.0
	_main.simulation.vertical_velocity = 1.0
	_main.simulation.air_duck_time = MainScript.TUNING.air_duck_dive_duration
	_main._update_player(0.01)
	var uses_compact_pose := pivot.scale.y < 1.0
	var stays_airborne := pivot.position.y > 0.75
	_main.simulation.player_y = 0.0
	_main.simulation.vertical_velocity = 0.0
	_main.simulation.air_duck_time = 0.0
	return uses_compact_pose and stays_airborne
```

- [ ] **Step 2: Run the active-scene smoke test and verify RED**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: FAIL with `Main scene does not show the compact airborne duck roll.`

- [ ] **Step 3: Apply the airborne compact pose**

In `_update_player()`, insert the airborne branch before the grounded duck branch:

```gdscript
if simulation.state == Simulation.RunState.IMPACT:
	_player_visual_pivot.scale = Vector3.ONE * 1.15
elif simulation.is_air_ducking():
	_player_visual_pivot.scale = Vector3(1.0, 0.55, 1.0)
elif simulation.duck_time > 0.0:
	_player_visual_pivot.scale = Vector3(1.0, 0.55, 1.0)
	_player_visual_pivot.position.y = 0.43
```

The airborne branch intentionally does not override `position.y`, so the compact sphere visibly dives from its current jump height while continuing its normal rolling rotation.

- [ ] **Step 4: Run the active-scene smoke test and verify GREEN**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: `Dog Run active scene smoke test passed.`

- [ ] **Step 5: Commit the visual slice**

```powershell
git add tests/test_main_smoke.gd game/main.gd
git commit -m "feat: show airborne duck roll"
```

### Task 4: Verify the Complete Feature

**Files:**
- Verify: `game/runner_simulation.gd`
- Verify: `game/runner_tuning.gd`
- Verify: `game/default_runner_tuning.tres`
- Verify: `game/main.gd`
- Verify: `tests/test_runner_simulation.gd`
- Verify: `tests/test_runner_tuning.gd`
- Verify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Run the complete simulation suite**

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
```

Expected: `Dog Run simulation tests passed.`

- [ ] **Step 2: Run scene and mobile regressions**

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_mobile_tap.gd
```

Expected:

```text
Dog Run active scene smoke test passed.
Dog Run mobile tap test passed.
```

- [ ] **Step 3: Review scope and repository state**

```powershell
git diff --check
git status --short
git log -4 --oneline --decorate
```

Expected: no whitespace errors, only intended changes or a clean worktree, and the design plus three implementation commits at `HEAD`.

- [ ] **Step 4: Manually verify the move**

Launch the game, jump, then duck at low and high points in the arc. Confirm the sphere immediately compacts, dives smoothly, remains safe under overhead bars, can still change lanes, rolls briefly after landing, and cannot jump until the roll ends.
