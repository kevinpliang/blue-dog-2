# Settings Sound Panel Design

## Goal

Add a simple settings panel that lets players control gameplay sound from the main menu and game-over screen without interrupting active runs.

## Entry Point

- Show a rounded-square settings button in the top-right on the main menu and game-over screen.
- Hide the settings button during active runs and impact/gameplay states.
- Use a checked-in Material settings SVG at `assets/icons/settings.svg` inside the button.
- Keep the rounded-square button background in Godot UI so the icon asset stays simple.

## Panel

The settings panel appears centered as a modal overlay. It blocks taps behind it so opening settings cannot accidentally start or restart a run.

Panel contents:

- `SETTINGS`
- `SOUND` toggle with `ON` / `OFF`
- `VOLUME` slider from `0%` to `100%`
- `CLOSE` button

The panel should use the existing Michroma font and white/cyan styling. It should be compact enough for portrait mobile screens.

## Audio Behavior

- Default sound is `ON`.
- Default volume is `100%`.
- `100%` preserves the current cue mix; the existing cue volume remains the maximum.
- Lower volume scales cue playback down from the current mix.
- If sound is `OFF`, gameplay cues do not play.
- If sound is `ON`, gameplay cues play at the selected volume.

## Persistence

Store settings in the existing `user://dog_run.cfg` file:

- `settings/sound_enabled`
- `settings/sound_volume`

Existing saves that do not contain these values load as sound `ON` and volume `1.0`.

## Architecture

`Main` owns the settings UI and save/load state because it already owns HUD construction and `ConfigFile` persistence.

`FeedbackController` receives runtime sound settings from `Main` and uses them when playing cues. `RunnerTuning.audio_enabled` remains a global default/kill switch, while the player setting controls per-save behavior.

## Testing

Smoke tests verify:

- The Material settings SVG is available and used by the settings button.
- The settings button appears on the ready and game-over screens.
- The settings button hides during active runs.
- Opening settings shows the modal panel.
- The modal blocks start/restart taps behind it.
- Sound toggle and volume slider values persist through save/load.
- Feedback audio respects sound enabled and volume settings.
