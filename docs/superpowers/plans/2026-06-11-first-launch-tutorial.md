# First-Launch Tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show swipe instructions on the ready screen once, then persist their completion after the first run starts.

**Architecture:** Keep tutorial state and presentation in `Main`, beside the existing HUD and `ConfigFile` persistence. The runner simulation and input interpreter remain unchanged.

**Tech Stack:** Godot 4, GDScript, `ConfigFile`

---

### Task 1: Add First-Launch Tutorial State

**Files:**
- Modify: `game/main.gd`
- Modify: `tests/test_main_smoke.gd`

- [ ] Add a smoke regression that verifies first-time tutorial text and first-tap completion.
- [ ] Run the smoke regression and confirm it fails before implementation.
- [ ] Load and save `progress/tutorial_completed` in the existing save file.
- [ ] Show tutorial text only for an incomplete tutorial on the ready screen.
- [ ] Complete and persist the tutorial when the first ready-screen tap starts a run.
- [ ] Run the simulation, active-scene, and mobile-input suites.
