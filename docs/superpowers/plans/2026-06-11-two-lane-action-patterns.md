# Two-Lane Action Patterns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add four starting obstacle patterns that encourage jumping and ducking.

**Architecture:** Extend the data-only tier-zero entries in `PatternLibrary`. Keep pattern selection, spawning, validation, rendering, and timing unchanged.

**Tech Stack:** Godot 4, GDScript

---

### Task 1: Add Two-Lane Action Rows

**Files:**
- Modify: `game/pattern_library.gd`

- [ ] Add left-center and center-right ground-block rows at tier zero.
- [ ] Add left-center and center-right overhead-bar rows at tier zero.
- [ ] Run the existing simulation, active-scene, and mobile-input suites.
