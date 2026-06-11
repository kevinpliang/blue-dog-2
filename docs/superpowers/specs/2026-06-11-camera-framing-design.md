# Camera Framing Design

## Goal

Make the player and nearby action feel larger on portrait mobile screens, with the player sitting in the moderate lower third of the screen, without changing gameplay timing or collision behavior.

## Approach

Use two rendering-only tuning values:

- Reduce the `Camera3D` field of view from `64.0` to `58.0`.
- Offset the rendered player, player light, and rendered obstacles by `+2.0` on the world Z axis.

The narrower field of view enlarges the whole action area coherently. Moving the shared visual action plane toward the camera places the player lower in the frame while keeping rendered collisions aligned.

## Gameplay Isolation

The runner simulation remains unchanged. Obstacles still collide, pass, spawn, and despawn using their existing simulation Z positions around `z = 0`. The visual action-plane offset is applied only when synchronizing scene nodes from simulation state.

Track geometry, camera position, camera look target, speed, obstacle spacing, and collision thresholds remain unchanged.

## Tunability

Add `camera_fov` and `visual_action_plane_z` to the existing `RunnerTuning` resource. This keeps the framing values easy to adjust after device playtesting without introducing a new camera system.

## Verification

Automated smoke coverage will verify:

- The active camera uses the tuned `58.0` degree FOV and keeps `KEEP_WIDTH`.
- The player renders at the tuned visual action plane.
- Rendered obstacles receive the same visual Z offset while their simulation Z values remain unchanged.
- The player light follows the player at the same visual Z position.

Manual verification should confirm the player sits in the moderate lower third and the view remains readable on phone and tablet portrait aspect ratios.

