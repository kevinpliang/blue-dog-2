# Movement Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add movement-based lane lean, jump stretch, landing squash, and speed-scaled cyan trails without changing gameplay.

**Architecture:** A player visual pivot owns lean and scale while the child sphere mesh keeps its rolling rotation. `Main` consumes existing landing events and updates one bounded world-space trail emitter.

**Tech Stack:** Godot 4.5, GDScript, Node3D transforms, GPUParticles3D

---

### Task 1: Add Movement Feedback Regression Coverage

**Files:**
- Modify: `tests/test_runner_tuning.gd`
- Modify: `tests/test_main_smoke.gd`

- [x] **Step 1: Add failing tuning assertions**

Require all movement-feedback tuning properties and their approved default values.

- [x] **Step 2: Add failing active-scene checks**

Require a named player visual pivot, one named speed-trail emitter, continued sphere rolling, lane lean after lateral movement, and landing-pulse activation after a `landed` event.

- [x] **Step 3: Run focused tests and verify RED**

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_runner.gd
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: failures because the tuning properties, pivot, and trail do not exist.

### Task 2: Implement Player Transform Feedback

**Files:**
- Modify: `game/runner_tuning.gd`
- Modify: `game/default_runner_tuning.tres`
- Modify: `game/main.gd`

- [x] **Step 1: Add tunable defaults**

Add lean, jump stretch, landing squash, landing duration, and trail properties to `RunnerTuning`.

- [x] **Step 2: Add the player visual pivot**

Position the pivot from simulation state. Keep the textured sphere as its child and keep rolling rotation on the sphere.

- [x] **Step 3: Apply lean and scale priority**

Calculate movement-based lean from lateral velocity, smooth it, and apply the approved scale priority. Consume `landed` events to start the landing-pulse timer.

### Task 3: Implement Speed Trails And Verify

**Files:**
- Modify: `game/main.gd`
- Modify: `docs/superpowers/plans/2026-06-11-movement-feedback.md`

- [x] **Step 1: Add one bounded trail emitter**

Create one named `GPUParticles3D` behind the player, set `local_coords = false`, and scale its amount ratio and particle velocity with runner speed.

- [x] **Step 2: Run all automated tests**

Run the simulation suite, active-scene smoke test, and mobile-tap regression.

- [x] **Step 3: Render and inspect portrait movement**

Capture a portrait active-run frame and confirm the trail is subtle and the player remains readable.

- [x] **Step 4: Review final scope**

Confirm gameplay simulation, collisions, input timing, and obstacle generation remain unchanged.
