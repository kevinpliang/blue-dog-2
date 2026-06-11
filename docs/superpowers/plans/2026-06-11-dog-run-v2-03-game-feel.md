# Dog Run V2 Phase 3: Game Feel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add clear, lightweight feedback for movement, obstacle clears, near misses, and collisions without changing gameplay rules.

**Architecture:** `RunnerSimulation` emits data-only gameplay events. A `FeedbackController` consumes events and owns pooled particles, camera shake, audio playback, vibration, and restart transition visuals. Feedback may be disabled through constants for testing or unsupported platforms.

**Tech Stack:** Godot 4, GDScript, built-in particles and audio APIs

---

### Task 1: Add simulation gameplay events

**Files:**
- Modify: `game/runner_simulation.gd`
- Modify: `tests/test_runner_simulation.gd`

- [ ] **Step 1: Write failing event tests**

Require `drain_events()` to return and clear events for:

- `lane_changed`
- `jumped`
- `landed`
- `ducked`
- `obstacle_cleared`
- `near_miss`
- `collision`

Prove an event is returned only once.

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement an event queue**

Use dictionaries:

```gdscript
{"type": "near_miss", "obstacle_id": 12}
```

Emit from existing state transitions and collision/obstacle-removal logic. A near miss occurs when an obstacle passes the player within a forgiving x/action margin without colliding.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/runner_simulation.gd tests/test_runner_simulation.gd
git commit -m "feat: emit gameplay feedback events"
```

### Task 2: Add pooled particles and camera shake

**Files:**
- Create: `game/feedback_controller.gd`
- Create: `tests/test_feedback_controller.gd`
- Modify: `game/main.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing controller tests**

Test that:

- impact requests reuse a bounded pool of `GPUParticles3D`
- collision starts shake
- shake returns camera offset to zero after its duration
- repeated events never grow the particle pool beyond its configured capacity

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement minimal visual feedback**

Create a `FeedbackController` node with:

```gdscript
const IMPACT_POOL_SIZE := 4
const SHAKE_DURATION := 0.18
const SHAKE_STRENGTH := 0.12
```

Use built-in particle meshes and no imported texture. Keep camera shake position-only and small.

- [ ] **Step 4: Wire event consumption in `Main`**

After `simulation.step(delta)`, drain events and pass them to the controller.

- [ ] **Step 5: Run tests and render-check collision**

- [ ] **Step 6: Commit**

```powershell
git add game/feedback_controller.gd game/main.gd tests/test_feedback_controller.gd tests/test_runner.gd
git commit -m "feat: add impact particles and camera shake"
```

### Task 3: Add procedural audio cues

**Files:**
- Create: `game/audio_cue_library.gd`
- Create: `tests/test_audio_cue_library.gd`
- Modify: `game/feedback_controller.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing audio-cue tests**

Require non-empty `AudioStreamWAV` cues for jump, landing, lane change, near miss, and collision. Assert generated samples are short and use a mobile-friendly sample rate.

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Generate simple cues in code**

Create mono procedural tones/noise at `22050 Hz`, each under `0.35s`. Avoid imported audio assets in this phase.

- [ ] **Step 4: Play cues through a small bounded player pool**

Map gameplay events to cues in `FeedbackController`.

- [ ] **Step 5: Verify tests and manually mix levels**

- [ ] **Step 6: Commit**

```powershell
git add game/audio_cue_library.gd game/feedback_controller.gd tests/test_audio_cue_library.gd tests/test_runner.gd
git commit -m "feat: add procedural gameplay audio"
```

### Task 4: Add optional haptics and restart transition

**Files:**
- Modify: `game/feedback_controller.gd`
- Modify: `game/main.gd`
- Modify: `tests/test_feedback_controller.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Add failing tests**

Require:

- haptic requests only for near-miss and collision events
- a project-level `HAPTICS_ENABLED` switch
- a named full-screen `RestartFade` control
- restart fade begins opaque and resolves to transparent

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement haptic adapter**

Call `Input.vibrate_handheld()` only when enabled and on supported platforms. Use a brief near-miss pulse and a stronger collision pulse.

- [ ] **Step 4: Implement restart fade**

Add a black `ColorRect` and tween its alpha during restart; do not delay simulation start by more than `0.2s`.

- [ ] **Step 5: Verify and device-check**

Test sound and haptics on at least one physical phone.

- [ ] **Step 6: Commit**

```powershell
git add game/feedback_controller.gd game/main.gd tests/test_feedback_controller.gd tests/test_main_smoke.gd
git commit -m "feat: add haptics and restart transition"
```

