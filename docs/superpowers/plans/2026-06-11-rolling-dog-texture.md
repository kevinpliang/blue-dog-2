# Rolling Dog Texture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Map the supplied portrait dog-face PNG onto the rolling player sphere without distorting or repeating it.

**Architecture:** Add a dedicated player material helper in `main.gd`. It applies the imported texture plus fixed UV scale/offset values appropriate for the supplied portrait image, while existing player animation remains unchanged.

**Tech Stack:** Godot 4.5, GDScript, StandardMaterial3D, headless scene smoke test

---

### Task 1: Add Player Texture Regression Coverage

**Files:**
- Modify: `tests/test_main_smoke.gd`

- [x] **Step 1: Add a failing textured-player check**

Verify the player uses `assets/player/white.png`, has portrait-preserving UV mapping, disables texture repetition, and rotates during an active run.

- [x] **Step 2: Run the active-scene smoke test and verify RED**

```powershell
& "$env:TEMP\godot-4.5.1\Godot_v4.5.1-stable_win64_console.exe" --headless --path . --script res://tests/test_main_smoke.gd
```

Expected: failure because the player still uses an untextured white material.

### Task 2: Map and Verify the Dog Texture

**Files:**
- Modify: `game/main.gd`
- Add: `assets/player/white.png`
- Add: `assets/player/white.png.import`

- [x] **Step 1: Add a dedicated player material**

Preload the texture and apply it to a `StandardMaterial3D` with centered portrait-preserving UV scale/offset and texture repetition disabled.

- [x] **Step 2: Run all automated tests**

Run the simulation suite, active-scene smoke test, and mobile tap regression.

- [x] **Step 3: Render and inspect a portrait frame**

Capture an iPhone-like frame. Adjust only the initial player orientation or UV offset if the dog face is not initially aimed toward the camera.

- [x] **Step 4: Review final scope**

Confirm the existing X-axis rolling animation, collision behavior, and gameplay simulation remain unchanged.
