# Dog Run V2 Phase 2: Patterns and Fairness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace independent random rows with deterministic curated multi-row patterns that remain reachable as difficulty increases.

**Architecture:** `PatternLibrary` owns data-only pattern definitions. `ReachabilityValidator` evaluates whether a pattern leaves at least one valid route given speed and action timing. `RunnerSimulation` selects valid patterns deterministically by difficulty tier and emits the same obstacle dictionaries consumed by rendering.

**Tech Stack:** Godot 4, GDScript, headless GDScript tests

---

### Task 1: Define curated pattern data

**Files:**
- Create: `game/pattern_library.gd`
- Create: `tests/test_pattern_library.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing pattern-library tests**

Require patterns with:

```gdscript
{
	"id": "single_ground_left",
	"tier": 0,
	"rows": [
		{"offset": 0.0, "obstacles": [{"lane": 0, "type": ObstacleType.GROUND_BLOCK}]},
	]
}
```

Test that every pattern has a unique id, tier `0..2`, ascending row offsets, lanes `0..2`, and at least one row.

- [ ] **Step 2: Run tests and verify RED**

Expected: missing `PatternLibrary`.

- [ ] **Step 3: Implement minimal library**

Create at least:

- 4 tier-0 single-row introduction patterns
- 5 tier-1 two-row lane-choice patterns
- 5 tier-2 three-row mixed-action patterns

Do not include impossible same-lane jump-to-duck combinations at minimum spacing.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/pattern_library.gd tests/test_pattern_library.gd tests/test_runner.gd
git commit -m "feat: add curated obstacle patterns"
```

### Task 2: Implement reachability validation

**Files:**
- Create: `game/reachability_validator.gd`
- Create: `tests/test_reachability_validator.gd`
- Modify: `tests/test_runner.gd`

- [ ] **Step 1: Write failing validator tests**

Cover:

- a single open lane is reachable
- a required one-lane move with enough travel time is reachable
- a required two-lane move without enough travel time is rejected
- a ground block may be passed by jumping
- an overhead bar may be passed by ducking
- an immediate ground-block then overhead-bar sequence is rejected when action timing cannot recover

Use actual simulation constants, including `DUCK_DURATION == 0.3` and `DUCK_COOLDOWN == 0.05`.

- [ ] **Step 2: Run tests and verify RED**

Expected: missing validator.

- [ ] **Step 3: Implement validator state search**

Represent possible states as:

```gdscript
{"lane": 0, "action": Action.GROUNDED}
{"lane": 1, "action": Action.JUMPING}
{"lane": 2, "action": Action.DUCKING}
```

For each row, compute travel time from offset difference and speed, expand reachable lane/action transitions, remove states colliding with the row, and reject when no state remains.

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/reachability_validator.gd tests/test_reachability_validator.gd tests/test_runner.gd
git commit -m "feat: validate obstacle pattern reachability"
```

### Task 3: Add difficulty tiers

**Files:**
- Modify: `game/runner_simulation.gd`
- Modify: `tests/test_runner_simulation.gd`

- [ ] **Step 1: Write failing tier tests**

Specify:

```gdscript
expect_equal(simulation.difficulty_tier_at_distance(0.0), 0, "run starts at tier zero")
expect_equal(simulation.difficulty_tier_at_distance(250.0), 1, "middle distance unlocks tier one")
expect_equal(simulation.difficulty_tier_at_distance(650.0), 2, "long distance unlocks tier two")
```

- [ ] **Step 2: Run tests and verify RED**

- [ ] **Step 3: Implement minimal tier function**

Use explicit thresholds:

```gdscript
const TIER_ONE_DISTANCE := 250.0
const TIER_TWO_DISTANCE := 650.0
```

- [ ] **Step 4: Run tests and verify GREEN**

- [ ] **Step 5: Commit**

```powershell
git add game/runner_simulation.gd tests/test_runner_simulation.gd
git commit -m "feat: add distance-based difficulty tiers"
```

### Task 4: Generate deterministic validated patterns

**Files:**
- Modify: `game/runner_simulation.gd`
- Modify: `tests/test_runner_simulation.gd`

- [ ] **Step 1: Replace row-generation tests with pattern-generation tests**

Test:

- same seed generates identical obstacle dictionaries
- tier-zero distance never selects tier-one or tier-two patterns
- generated pattern ids become more varied after thresholds
- every accepted generated pattern passes `ReachabilityValidator`
- invalid candidate patterns are skipped deterministically

- [ ] **Step 2: Run tests and verify RED**

Expected: simulation still generates independent rows.

- [ ] **Step 3: Integrate patterns**

Replace `_spawn_row()` with `_spawn_next_pattern()`. Select a pattern from unlocked tiers using `_rng`, validate it at current speed, append its rows using existing obstacle dictionary keys, then leave a recovery gap before the next pattern.

- [ ] **Step 4: Run full headless tests and verify GREEN**

- [ ] **Step 5: Render active-run verification**

Capture a seeded active run and confirm multi-row patterns remain visually readable.

- [ ] **Step 6: Commit**

```powershell
git add game/runner_simulation.gd tests/test_runner_simulation.gd
git commit -m "feat: generate deterministic fair patterns"
```

