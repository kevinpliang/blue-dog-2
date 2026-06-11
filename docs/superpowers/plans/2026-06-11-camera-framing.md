# Camera Framing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enlarge the portrait action area and place the player in the moderate lower third without changing simulation behavior.

**Architecture:** Add camera FOV and visual action-plane values to the existing runner tuning resource. `main.gd` will use those values only when positioning render nodes, keeping all simulation coordinates and collision logic unchanged.

**Tech Stack:** Godot 4.5, GDScript, headless scene smoke tests

---

### Task 1: Add Framing Regression Coverage

**Files:**
- Modify: `tests/test_runner_tuning.gd`
- Modify: `tests/test_main_smoke.gd`

- [x] **Step 1: Add failing tuning assertions**

Add assertions that `TUNING.camera_fov` equals `58.0` and `TUNING.visual_action_plane_z` equals `2.0`.

- [x] **Step 2: Add a failing active-scene framing check**

Add a smoke-test helper that confirms the camera FOV, player Z, player-light Z, and rendered obstacle Z offset match the tuning resource while the source simulation obstacle Z remains unchanged.

- [x] **Step 3: Run tests to verify they fail**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: failures because the framing tuning properties and rendering behavior do not exist yet.

### Task 2: Implement Tuned Camera Framing

**Files:**
- Modify: `game/runner_tuning.gd`
- Modify: `game/default_runner_tuning.tres`
- Modify: `game/main.gd`

- [x] **Step 1: Add the tuning values**

Add:

```gdscript
@export var camera_fov := 58.0
@export var visual_action_plane_z := 2.0
```

and set the same values in `default_runner_tuning.tres`.

- [x] **Step 2: Apply the FOV and visual action plane**

Use `TUNING.camera_fov` when building the camera. Set the player Z and player-light Z to `TUNING.visual_action_plane_z`, and add that offset to each rendered obstacle Z in `_sync_obstacles()`.

- [x] **Step 3: Run focused tests to verify they pass**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: both commands exit successfully.

### Task 3: Verify Mobile Framing

**Files:**
- No production file changes expected

- [x] **Step 1: Run the mobile input regression**

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_mobile_tap.gd
```

Expected: exit code `0`.

- [x] **Step 2: Render portrait screenshots**

Render the game at `405x720`, `591x1280`, and `600x800` to verify the moderate lower-third framing remains readable across portrait aspect ratios.

- [x] **Step 3: Review the final diff**

Confirm only the approved rendering, tuning, test, spec, and plan files changed, and that simulation code is untouched.
