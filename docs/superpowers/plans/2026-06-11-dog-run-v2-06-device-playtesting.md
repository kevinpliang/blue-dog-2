# Dog Run V2 Phase 6: Device Playtesting and Tuning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tune Dog Run from structured Android and iOS playtests until the core run remains fair, readable, and engaging for at least three minutes.

**Architecture:** Move tunable values into one `RunnerTuning` resource consumed by simulation, input, rendering, and feedback. Use a repeatable device test script and record results in a versioned playtest log before changing values.

**Tech Stack:** Godot 4 resources, GDScript, Android and iOS devices

---

### Task 1: Centralize tunable values

**Files:**
- Create: `game/runner_tuning.gd`
- Create: `game/default_runner_tuning.tres`
- Create: `tests/test_runner_tuning.gd`
- Modify: `game/runner_simulation.gd`
- Modify: `game/input_interpreter.gd`
- Modify: `game/feedback_controller.gd`
- Modify: `game/main.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing default-value tests**

Require the resource to expose current approved values, including:

```gdscript
duck_duration = 0.3
duck_cooldown = 0.05
start_speed = 12.0
max_speed = 24.0
speed_acceleration = 0.35
lane_change_speed = 16.0
jump_velocity = 9.5
gravity = 24.0
input_buffer_duration = 0.12
swipe_width_ratio = 50.0 / 720.0
```

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Create tuning resource**

Define exported typed properties and a checked-in default `.tres`. Inject or load the resource in each consumer. Remove duplicated tunable constants only after their tests pass through the resource.

- [ ] **Step 4: Run all tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/runner_tuning.gd game/default_runner_tuning.tres game/runner_simulation.gd game/input_interpreter.gd game/feedback_controller.gd game/main.gd tests/test_runner_tuning.gd tests/test_runner.gd
git commit -m "refactor: centralize runner tuning"
```

### Task 2: Create the structured playtest protocol

**Files:**
- Create: `docs/playtesting/v2-device-test-protocol.md`
- Create: `docs/playtesting/v2-playtest-log.md`

- [ ] **Step 1: Write the protocol**

Require each device session to record:

- device model, OS version, and build identifier
- three uninterrupted runs
- average and worst frame timing
- swipe misses by direction
- deaths judged unfair or unreadable
- longest run duration
- sound and haptic comfort
- track-fade readability
- notes on jump, lane, and duck feel

- [ ] **Step 2: Define pass criteria**

The phase passes when:

- no track endpoint is visible
- no known generated pattern is unreachable
- no repeated missed-swipe category remains
- the game holds the target frame rate during a three-minute run
- at least one tester completes or nearly completes a three-minute fair run
- Android and iOS have no lifecycle or safe-area blocker

- [ ] **Step 3: Commit**

```powershell
git add docs/playtesting/v2-device-test-protocol.md docs/playtesting/v2-playtest-log.md
git commit -m "docs: add v2 device playtest protocol"
```

### Task 3: Run Android playtest and tune

**Files:**
- Modify: `docs/playtesting/v2-playtest-log.md`
- Modify when evidence supports it: `game/default_runner_tuning.tres`
- Modify when a bug is found: relevant production and test files

- [ ] **Step 1: Export and install Android debug build**

Follow `docs/mobile-build-checklist.md`.

- [ ] **Step 2: Complete the protocol**

Record all observations before changing tuning.

- [ ] **Step 3: Fix reproducible bugs test-first**

For each unfair pattern or input failure, add a failing deterministic test using the recorded seed or gesture values, then implement the minimal fix.

- [ ] **Step 4: Adjust only evidence-supported tuning**

Preserve `duck_duration = 0.3` and `duck_cooldown = 0.05` unless a new explicit product decision approves changing them.

- [ ] **Step 5: Re-run protocol and commit**

```powershell
git add docs/playtesting/v2-playtest-log.md game/default_runner_tuning.tres game tests
git commit -m "tune: apply Android playtest findings"
```

### Task 4: Run iOS playtest and tune

**Files:**
- Modify: `docs/playtesting/v2-playtest-log.md`
- Modify when evidence supports it: `game/default_runner_tuning.tres`
- Modify when a bug is found: relevant production and test files

- [ ] **Step 1: Export and install iOS debug build on macOS**

Follow `docs/mobile-build-checklist.md`.

- [ ] **Step 2: Complete the protocol**

Pay particular attention to safe areas, lifecycle behavior, swipe thresholds, haptics, and audio latency.

- [ ] **Step 3: Fix reproducible bugs test-first**

- [ ] **Step 4: Adjust only evidence-supported tuning**

- [ ] **Step 5: Re-run protocol and commit**

```powershell
git add docs/playtesting/v2-playtest-log.md game/default_runner_tuning.tres game tests
git commit -m "tune: apply iOS playtest findings"
```

### Task 5: Complete v2 acceptance pass

**Files:**
- Modify: `docs/playtesting/v2-playtest-log.md`
- Modify: `docs/mobile-build-checklist.md`

- [ ] **Step 1: Run full automated verification**

Run simulation, input, patterns, fairness, feedback, scoring, lifecycle, runtime-bounds, tuning, smoke, and headless startup tests.

- [ ] **Step 2: Run final three-minute device sessions**

Complete one Android and one iOS session using the final tuning resource.

- [ ] **Step 3: Record residual risks**

List any device classes not tested, performance margins, and deferred improvements.

- [ ] **Step 4: Commit**

```powershell
git add docs/playtesting/v2-playtest-log.md docs/mobile-build-checklist.md
git commit -m "docs: complete v2 acceptance pass"
```

