# Dog Run Godot 4 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the smallest playable Godot 4 version of the approved Dog Run infinite-runner design.

**Architecture:** A pure `RunnerSimulation` owns gameplay state and deterministic obstacle generation. A single `Main` scene builds primitive visuals and HUD in code, forwards input to the simulation, and persists the high score.

**Tech Stack:** Godot 4, GDScript, built-in primitive 3D meshes, `ConfigFile`

---

### Task 1: Create the Godot project shell

**Files:**
- Create: `project.godot`
- Create: `game/main.tscn`

- [x] Configure a portrait GL Compatibility project.
- [x] Point the project at the main scene.
- [x] Add a minimal `Node3D` main scene.

### Task 2: Build gameplay rules test-first

**Files:**
- Create: `game/runner_simulation.gd`
- Create: `tests/test_runner_simulation.gd`
- Create: `tests/test_runner.gd`

- [x] Write tests for lanes, jump, duck, scoring, speed, generation, fairness, collision, and high score.
- [x] Run the tests and confirm they fail because the simulation is missing.
- [x] Implement the smallest simulation that satisfies the tests.
- [x] Run the headless test suite and confirm it passes.

### Task 3: Build the playable primitive scene

**Files:**
- Create: `game/main.gd`

- [x] Create camera, lighting, track, lane lines, player sphere, and HUD in code.
- [x] Forward touch swipes, mouse taps, and arrow keys to the simulation.
- [x] Render and pool obstacle nodes from simulation state.
- [x] Add run start, impact, game-over, score, and high-score flow.
- [x] Add local high-score persistence and app-focus pausing.

### Task 4: Verify the project

**Files:**
- Verify: all project files

- [x] Run the headless simulation tests.
- [x] Run the project headlessly long enough to detect parse and startup errors.
- [x] Review the implementation against the Godot design spec.
