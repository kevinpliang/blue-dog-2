# Balanced Pattern Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add eight balanced tier-1 and tier-2 obstacle patterns.

**Architecture:** Extend the existing data-only `PatternLibrary`. Keep spawning, rendering, collision handling, and the reachability validator unchanged.

**Tech Stack:** Godot 4, GDScript

---

### Task 1: Define Pattern Expectations

**Files:**
- Modify: `tests/test_pattern_library.gd`

- [ ] Assert the eight new IDs exist at their intended tiers.
- [ ] Assert every new pattern is reachable at maximum speed.
- [ ] Assert jump-to-duck and duck-to-jump patterns preserve their approved recovery spacing.
- [ ] Run the simulation suite and confirm it fails before implementation.

### Task 2: Add Balanced Patterns

**Files:**
- Modify: `game/pattern_library.gd`

- [ ] Add four tier-1 action-gate and action-then-route patterns.
- [ ] Add four tier-2 recovery-aware and lane-weave patterns.
- [ ] Run simulation, active-scene, and mobile-input suites.
- [ ] Commit and push the verified pattern expansion.

