# Movement Feedback Design

## Goal

Make lane changes, jumps, landings, and increasing speed feel more responsive without changing simulation movement, collision rules, or input timing.

## Player Transform Structure

Add a lightweight `Node3D` visual pivot at the player's rendered position. The textured sphere remains a child of that pivot.

- The pivot owns movement-based lane lean and squash/stretch scale.
- The sphere mesh owns its existing rolling rotation.
- The player light and feedback event position follow the pivot.

This prevents lean rotation from interfering with the rolling dog texture.

## Effects

### Movement-Based Lane Lean

Estimate lateral velocity from the change in `simulation.current_x` each frame. Convert it to a capped Z-axis lean and smoothly interpolate toward the target. When lateral movement stops, the pivot smoothly returns upright.

### Jump Stretch

While airborne and rising, stretch the pivot vertically and narrow it horizontally. Ease the effect toward normal near the apex and during descent.

### Landing Pulse

Consume the existing `landed` event to start a short timer. While active, apply a brief wide, short squash that eases back to normal.

### Speed Trails

Add one bounded `GPUParticles3D` trail emitter behind the player. It emits small cyan particles in world space. Emission amount and particle speed scale gently from runner start speed to maximum speed.

## Effect Priority

Visual scale priority is:

1. collision impact
2. duck
3. landing pulse
4. jump stretch
5. normal

Lane lean remains active during ordinary movement but returns upright during impact.

## Tuning

Expose the following values in `RunnerTuning`:

- `lane_lean_max_degrees`
- `lane_lean_smoothing`
- `jump_stretch_horizontal`
- `jump_stretch_vertical`
- `landing_squash_horizontal`
- `landing_squash_vertical`
- `landing_pulse_duration`
- `speed_trail_min_amount_ratio`
- `speed_trail_max_amount_ratio`
- `speed_trail_min_velocity`
- `speed_trail_max_velocity`

## Verification

Automated checks cover tuning values, the visual pivot, a bounded trail emitter, landing-pulse activation, lean response, and continued textured-sphere rolling. Portrait rendering verifies the effects remain subtle and readable.

