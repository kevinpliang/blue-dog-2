# Dog Run V2 Phase 5: Mobile Release Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Dog Run consistently buildable, bounded, lifecycle-safe, and measurable on Android and iOS.

**Architecture:** Keep gameplay unchanged. Add export configuration, lifecycle regression coverage, bounded-pool assertions, lightweight performance sampling, and an exact manual mobile build checklist.

**Tech Stack:** Godot 4, GDScript, Android export, iOS export

---

### Task 1: Harden pause and resume behavior

**Files:**
- Modify: `game/main.gd`
- Create: `tests/test_lifecycle.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing lifecycle tests**

Instantiate `Main`, start a run, record distance, call an explicit `set_app_paused(true)`, process time, and assert distance is unchanged. Resume and assert distance advances.

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Extract lifecycle setter**

Route `_notification()` through:

```gdscript
func set_app_paused(value: bool) -> void:
	_app_paused = value
```

Ensure active audio and haptics stop or suspend while paused.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/main.gd tests/test_lifecycle.gd tests/test_runner.gd
git commit -m "fix: harden mobile pause and resume"
```

### Task 2: Assert bounded runtime pools

**Files:**
- Modify: `game/main.gd`
- Modify: `game/feedback_controller.gd`
- Create: `tests/test_runtime_bounds.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing long-run bound tests**

Run a collision-disabled simulation/render loop for five simulated minutes and assert:

- obstacle node count remains below the maximum visible obstacle count plus a fixed reserve
- particle pool remains fixed
- audio player pool remains fixed
- event queue drains and remains bounded

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Enforce explicit capacities**

Define and enforce:

```gdscript
const MAX_OBSTACLE_NODES := 48
const MAX_PARTICLE_NODES := 4
const MAX_AUDIO_PLAYERS := 8
```

Reuse or discard excess requests; never grow pools after initialization.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/main.gd game/feedback_controller.gd tests/test_runtime_bounds.gd tests/test_runner.gd
git commit -m "perf: bound runtime object pools"
```

### Task 3: Add lightweight performance sampling

**Files:**
- Create: `game/performance_monitor.gd`
- Create: `tests/test_performance_monitor.gd`
- Modify: `game/main.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing aggregation tests**

Test that samples aggregate into average frame time, worst frame time, and frames below the `60 FPS` target without logging every frame.

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement monitor**

Collect one-second windows and print a concise diagnostic line only in debug builds:

```text
DogRun perf: avg=16.1ms worst=23.4ms slow=2 obstacles=18
```

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/performance_monitor.gd game/main.gd tests/test_performance_monitor.gd tests/test_runner.gd
git commit -m "perf: add lightweight frame sampling"
```

### Task 4: Add mobile export presets

**Files:**
- Create: `export_presets.cfg`
- Modify: `project.godot`
- Create: `docs/mobile-build-checklist.md`

- [ ] **Step 1: Configure project identity**

Set an explicit application version, portrait orientation, and mobile-safe stretch behavior in `project.godot`.

- [ ] **Step 2: Add Android preset**

Create an Android debug export preset with package id `com.kevin.dogrun`, portrait orientation, and default debug signing. Leave release keystore fields unset and documented.

- [ ] **Step 3: Add iOS preset**

Create an iOS preset with bundle id `com.kevin.dogrun`, portrait orientation, and documented placeholders for Apple team/signing values.

- [ ] **Step 4: Write exact build checklist**

Document:

- required Godot export templates
- Android SDK/JDK paths
- iOS macOS/Xcode requirement
- debug export commands
- install/launch steps
- signing fields required before release

- [ ] **Step 5: Verify available exports**

Run:

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --export-debug "Android" build/dog-run-debug.apk
```

Expected: APK succeeds when Android export templates and SDK are installed; otherwise document the exact missing prerequisite. Verify iOS export on macOS.

- [ ] **Step 6: Commit**

```powershell
git add export_presets.cfg project.godot docs/mobile-build-checklist.md
git commit -m "build: add mobile export configuration"
```

