# Airborne Duck Roll Design

## Goal

Allow a duck input during a jump to immediately protect the player from overhead bars, force a quick controlled descent, and transition into the existing short ground roll.

## Behavior

- Ducking while airborne immediately activates the duck collision state.
- The player descends smoothly from their current height to the ground over an adjustable `air_duck_dive_duration`, initially `0.12` seconds.
- The existing `0.3` second ground duck begins when the player lands. Its existing `0.05` second cooldown remains unchanged.
- Jump input is ignored while the airborne dive or landing roll is active. It is not buffered for the end of the roll.
- Lane changes remain available throughout the dive and roll.
- Ground blocks retain their normal collision behavior, so a dive that brings the player too low near a ground block can cause an impact.

## Simulation

The runner simulation tracks whether an airborne duck dive is active and the remaining dive time. Starting a dive clears any buffered jump, activates duck collision immediately, and emits an `air_duck_started` event.

Each simulation step moves the player toward the ground based on the remaining height and dive time, producing a consistent dive duration regardless of jump height. On landing, the dive state clears and the normal duck timer and cooldown begin.

Calling duck while grounded continues to use the existing ground-duck behavior. Calling duck again during a dive or active roll has no effect.

## Visual Feedback

The sphere continues its normal forward rolling rotation during the dive and ground roll. During the dive, the player visual uses a compact roll pose so the action is readable before landing. Existing landing feedback remains in place.

## Tuning

Add `air_duck_dive_duration` to `RunnerTuning`, with a default value of `0.12`.

## Testing

Simulation tests cover:

- Airborne duck immediately activates duck collision.
- The dive reaches the ground in approximately the configured duration.
- Landing transitions into the normal duck timer and cooldown.
- Jump input is ignored during both the dive and landing roll.
- Lane changes remain available during the move.
- Existing grounded duck timing remains unchanged.

The active-scene smoke test verifies the compact airborne-roll visual.
