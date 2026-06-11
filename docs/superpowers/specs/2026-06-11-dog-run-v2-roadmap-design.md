# Dog Run V2 Roadmap Design

## Goal

Dog Run v2 should make the core run satisfying, fair, readable, and release-ready on mobile while preserving the small scope and abstract visual identity of v1.

V2 is intentionally split into six independently playable phases. Each phase has its own implementation plan and verification checkpoint. Coins, skins, accounts, online leaderboards, turns, ramps, branching tracks, and backend services remain out of scope.

## Locked V1 Tuning

The current duck timing is intentional and must remain unchanged unless later device playtesting produces a new explicit decision:

- duck duration: `0.3s`
- post-duck cooldown: `0.05s`

## Phase 1: Infinite Fading Track and Mobile Control Feel

The visible track must continue into the distance without a hard cutoff. Replace the finite visual endpoint with a lightweight spatial shader that fades the dark track and cyan lines into the black background before their far geometry ends. Geometry remains finite and inexpensive, but its endpoint is hidden by the fade.

Improve control feel without changing the core move set:

- move swipe interpretation into a small testable input interpreter
- normalize swipe thresholds against viewport size
- add short jump and duck input buffers
- preserve chained lane changes
- preserve the locked duck timing
- make HUD layout respect mobile safe areas

Real-device tuning is deferred to Phase 6.

## Phase 2: Curated Obstacle Patterns and Reachability

Replace independent random rows with deterministic curated multi-row patterns. Patterns describe obstacle type, lane, and spacing between rows. Difficulty tiers unlock increasingly demanding patterns while preserving the existing speed ramp.

A pure reachability validator simulates which lanes and actions remain possible between pattern rows. A generated pattern is accepted only when at least one route remains reachable from the player's possible current states. Seeded generation must remain reproducible.

## Phase 3: Game Feel Feedback

Add feedback that reinforces existing actions without changing gameplay rules:

- pooled impact particles
- small collision camera shake
- jump, landing, lane-change, collision, and near-miss sound cues
- optional mobile vibration where supported
- smooth visual restart transition
- near-miss detection and feedback

Feedback events originate from simulation state changes and are consumed by the scene. Sound and haptics must be individually disableable in project-level tuning constants, but no settings menu is required.

## Phase 4: Scoring Depth

Keep distance as the base score and add a clean-clear multiplier:

- clearing obstacles without collision increments a streak
- streak thresholds increase the multiplier
- near misses grant a small bonus
- collision ends the run
- game-over overlay shows distance, multiplier peak, near misses, and final score

High score becomes final score rather than raw distance. Existing saved scores remain valid numeric high scores.

## Phase 5: Mobile Release Readiness

Prepare the project for reliable mobile builds:

- explicit Android and iOS export presets
- app identity, version, and orientation configuration
- safe pause/resume behavior
- bounded obstacle and feedback pools
- release-mode performance instrumentation
- documented mobile build and smoke-test checklist

Store submission, monetization, analytics, and backend services remain out of scope.

## Phase 6: Device Playtesting and Final Tuning

Run structured playtests on at least one representative Android device and one iOS device. Record:

- frame-rate stability
- swipe recognition failures
- unfair or unreadable patterns
- typical run duration
- control timing preferences
- visual readability and audio/haptic comfort

Tune values through a central configuration resource rather than scattering constants through gameplay code. The phase is complete when the core run remains fair and engaging for at least three minutes and no device-specific blocker remains.

## Architecture Changes

Keep `RunnerSimulation` as the source of gameplay truth. Extract only responsibilities that gain meaningful isolation:

- `RunnerTuning`: central gameplay and presentation constants
- `InputInterpreter`: converts pointer gestures into buffered gameplay commands
- `PatternLibrary`: curated deterministic obstacle definitions
- `ReachabilityValidator`: validates pattern fairness
- `FeedbackController`: consumes gameplay events and plays visual/audio/haptic feedback

`Main` remains responsible for scene construction, rendering, HUD, persistence, and mobile lifecycle, but delegates the new focused responsibilities above.

## Testing

Automated headless tests cover:

- input threshold normalization and buffering
- locked duck timing regression
- deterministic pattern selection
- reachability validation and rejection of unfair patterns
- difficulty-tier progression
- near-miss and clear events
- multiplier and final-score rules
- bounded pools
- pause/resume simulation behavior

Rendering, shader fade quality, sound mix, haptics, device performance, export builds, and play feel require manual verification.

## Phase Completion Rule

Each phase must:

- keep all prior automated tests passing
- add focused tests for new pure logic
- boot the main scene without parser or startup errors
- produce a manually verifiable playable build
- update the device/manual verification checklist where applicable

