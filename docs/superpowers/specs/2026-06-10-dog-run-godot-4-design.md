# Dog Run Godot 4 Design

## Summary

Dog Run is a portrait-only mobile infinite runner for iOS and Android. The player controls a rolling sphere on a straight three-lane track, using swipe gestures to change lanes, jump, and duck. The visual style is intentionally minimal: primitive 3D shapes, a black background, a dark track, cyan lane lines, a white player sphere, and colored obstacles.

The Godot 4 v1 target is a playable local prototype with distance scoring and local high-score persistence. It does not include accounts, backend leaderboards, coins, powerups, sound, haptics, store packaging, settings, pause menus, character selection, turns, ramps, or non-straight track sections.

## Platform and Architecture

The app is a Godot 4 GDScript project using the GL Compatibility renderer for broad mobile support. The project defaults to a portrait 720 by 1280 viewport.

The main scene owns:

- primitive 3D rendering
- swipe, mouse, and keyboard input
- HUD and session overlays
- local high-score persistence through `ConfigFile`
- application focus pause and resume behavior

Core gameplay rules live in a small `RefCounted` simulation class outside the renderer:

- run-state transitions
- player lane interpolation
- jump and duck timers
- speed ramping
- deterministic obstacle generation
- fairness by always leaving at least one lane open
- distance scoring
- forgiving logical collision detection

The renderer reads simulation state each frame and updates pooled obstacle mesh nodes. It does not own gameplay decisions.

## Camera, World, and Visual Style

The game uses a fixed behind-runner `Camera3D`. The player stays near the world origin while obstacles move toward it, avoiding unbounded forward coordinates.

The track is a long static dark box with thin cyan lane-divider boxes. The player and all obstacles use built-in primitive meshes and simple materials. There are no shadows, textures, imported assets, or post-processing effects.

## Session Flow

The app opens directly to the game scene with a centered `Tap to Start` overlay. Tapping starts a run. Collision stops gameplay immediately, holds a short 300 ms impact state, then shows `Game Over / Tap to Restart`.

Score is whole meters of simulated travel. High score is loaded from and saved to `user://dog_run.cfg`.

If the app loses focus or is paused by the operating system, simulation updates stop until focus resumes.

## Controls and Player Movement

Production controls are swipe gestures:

- swipe left or right changes the target lane by one
- swipe up jumps while grounded
- swipe down ducks while grounded
- short taps start or restart, and are ignored during a run

Arrow keys provide hidden desktop development controls.

The target lane can change again before the previous lane interpolation finishes. Jumping and lane changes may happen together. Ducking lasts 300 ms and has a 50 ms post-duck cooldown. Swipe down while airborne has no effect.

## Obstacles and Difficulty

V1 includes:

- ground block: avoid by changing lanes or jumping
- overhead bar: avoid by changing lanes or ducking
- lane wall: avoid by changing lanes

Rows are selected deterministically from simple one-obstacle and two-obstacle patterns. Every row leaves at least one lane empty, which is the v1 fairness guarantee. Speed increases continuously to a cap, while row spacing tightens slightly as speed increases.

Collision is calculated from the player's interpolated x-position, vertical state, and duck state. Hit ranges are smaller than the visible meshes.

## Testing Strategy

A headless GDScript test runner covers:

- lane transitions, edge limits, and chained changes
- jump and duck behavior
- speed cap and distance scoring
- deterministic obstacle generation
- open-lane fairness
- collision using interpolated player position
- high-score update rules

Rendering, swipe feel, camera framing, and mobile performance remain manual checks.

## Out of Scope for V1

- store packaging
- backend services or accounts
- coins, powerups, lives, or enemies
- turns, ramps, curves, or branches
- settings, pause menu, tutorial, sound, or haptics
- imported art or animation assets

## Approved Decisions

- Engine: Godot 4
- Language: GDScript
- Renderer: GL Compatibility
- Player: rolling white sphere
- Camera: fixed behind-runner
- Track: straight, three lanes
- Orientation: portrait
- Controls: swipe with hidden arrow-key controls
- High score: local `ConfigFile`
- Scoring: distance only
- Difficulty: continuous speed ramp with a cap
- Collision feel: forgiving
- Implementation bias: smallest playable v1
