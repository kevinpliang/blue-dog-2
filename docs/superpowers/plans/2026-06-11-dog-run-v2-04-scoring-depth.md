# Dog Run V2 Phase 4: Scoring Depth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reward clean obstacle clears and near misses with a simple multiplier while keeping distance understandable.

**Architecture:** `RunnerSimulation` owns score inputs, streak, multiplier, and final-score calculation because they are deterministic gameplay rules. `Main` renders the live multiplier and a game-over run summary, then persists final score using the existing high-score file.

**Tech Stack:** Godot 4, GDScript, `ConfigFile`

---

### Task 1: Implement streak and multiplier rules

**Files:**
- Modify: `game/runner_simulation.gd`
- Modify: `tests/test_runner_simulation.gd`

- [ ] **Step 1: Write failing multiplier tests**

Specify:

```gdscript
expect_equal(simulation.multiplier_for_streak(0), 1, "run starts at x1")
expect_equal(simulation.multiplier_for_streak(5), 2, "five clears reaches x2")
expect_equal(simulation.multiplier_for_streak(15), 3, "fifteen clears reaches x3")
expect_equal(simulation.multiplier_for_streak(30), 4, "thirty clears reaches cap")
```

Test that each cleared obstacle increments streak once and collision freezes the final multiplier peak.

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement score state**

Add:

```gdscript
var clear_streak := 0
var multiplier := 1
var peak_multiplier := 1
var near_miss_count := 0
```

Update these from gameplay events. Reset them on `start()`.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/runner_simulation.gd tests/test_runner_simulation.gd
git commit -m "feat: add clear streak multiplier"
```

### Task 2: Define final-score calculation

**Files:**
- Modify: `game/runner_simulation.gd`
- Modify: `tests/test_runner_simulation.gd`

- [ ] **Step 1: Write failing score tests**

Lock the formula:

```gdscript
final_score = distance_score + clear_bonus + near_miss_bonus
clear_bonus = cleared_obstacle_count * 10 * multiplier_at_clear
near_miss_bonus = near_miss_count * 25
```

Test deterministic totals and prove `distance_score()` remains whole meters.

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement explicit scoring methods**

Add `distance_score()`, `final_score()`, and accumulated bonus fields. Keep `score()` as a temporary alias to `final_score()` only after updating all call sites.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/runner_simulation.gd tests/test_runner_simulation.gd
git commit -m "feat: calculate final run score"
```

### Task 3: Add live multiplier HUD and run summary

**Files:**
- Modify: `game/main.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Write failing HUD smoke assertions**

Require named labels:

- `MultiplierLabel`
- `RunSummaryLabel`

Require the summary to include distance, peak multiplier, near misses, and final score after game over.

- [ ] **Step 2: Run smoke test and verify RED**

- [ ] **Step 3: Implement HUD**

Show multiplier near the live score only when above x1. On game over, display:

```text
GAME OVER
Distance  412m
Peak  x3
Near Misses  4
Score  1387
Tap to Restart
```

- [ ] **Step 4: Run smoke test and render-check portrait layout**

- [ ] **Step 5: Commit**

```powershell
git add game/main.gd tests/test_main_smoke.gd
git commit -m "feat: show multiplier and run summary"
```

### Task 4: Persist final-score high score safely

**Files:**
- Modify: `game/main.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] **Step 1: Add persistence regression coverage**

Test that an existing numeric `scores/high_score` loads unchanged and that only a higher final score replaces it.

- [ ] **Step 2: Update high-score call sites**

Use `simulation.final_score()` at game over. Do not change the save path or value key, preserving existing saves.

- [ ] **Step 3: Verify**

Run all tests and manually confirm an existing `user://dog_run.cfg` still loads.

- [ ] **Step 4: Commit**

```powershell
git add game/main.gd tests/test_main_smoke.gd
git commit -m "feat: persist final-score high score"
```

