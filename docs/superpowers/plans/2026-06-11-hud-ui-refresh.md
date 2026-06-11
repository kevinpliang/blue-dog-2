# HUD UI Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply Michroma typography, create a stacked running HUD, and replace the post-run text block with an aligned summary.

**Architecture:** Keep HUD construction and state updates in `Main`. Replace individually positioned score/high-score labels and the free-form summary label with a top-right `VBoxContainer` and a centered post-run `VBoxContainer` containing a two-column `GridContainer`.

**Tech Stack:** Godot 4, GDScript, Godot containers, Michroma TTF

---

### Task 1: Define HUD Behavior

**Files:**
- Modify: `tests/test_main_smoke.gd`

- [ ] Add active-run assertions for Michroma, a visible stacked score/multiplier HUD, and no high-score HUD.
- [ ] Add post-run assertions for aligned summary metrics and the new-high-score heading.
- [ ] Run the smoke test and confirm it fails before implementation.

### Task 2: Build The Refreshed HUD

**Files:**
- Modify: `game/main.gd`
- Add: `assets/fonts/Michroma-Regular.ttf`

- [ ] Preload Michroma and apply it in the shared label styling helper.
- [ ] Build a top-right score stack with a large score and always-visible cyan multiplier.
- [ ] Build a centered post-run summary with a new-high-score heading and aligned metric grid.
- [ ] Track new-high-score status before updating persisted high score.
- [ ] Show and hide the correct HUD groups for ready, running, and game-over states.

### Task 3: Verify Mobile Layout

**Files:**
- Modify: `tests/test_main_smoke.gd`

- [ ] Run simulation, active-scene, and mobile-input suites.
- [ ] Render active-run and post-run portrait frames and inspect hierarchy, alignment, and safe-area placement.
- [ ] Commit and push only the HUD refresh, font asset, tests, spec, and plan.
