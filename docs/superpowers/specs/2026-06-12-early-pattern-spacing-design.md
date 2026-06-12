# Early Pattern Spacing Design

## Goal

Make the beginning of each run easier by increasing the empty distance between obstacle patterns, then smoothly return to the existing spacing as the player approaches tier one.

## Behavior

- At `0m`, separate obstacle patterns have an `18m` gap.
- The gap smoothly decreases as run distance increases.
- At `250m`, spacing reaches the existing speed-based formula and continues using it for the rest of the run.
- Internal row offsets within curated patterns remain unchanged.
- Pattern selection, difficulty-tier unlocks, runner speed, and obstacle collision behavior remain unchanged.

## Tuning

Add these adjustable properties to `RunnerTuning`:

- `early_pattern_spacing = 18.0`
- `early_spacing_end_distance = 250.0`
- `normal_pattern_spacing_base = 15.0`
- `normal_pattern_spacing_speed_factor = 0.25`
- `minimum_pattern_spacing = 9.0`

The normal pattern gap remains:

```text
max(minimum_pattern_spacing, normal_pattern_spacing_base - speed * normal_pattern_spacing_speed_factor)
```

The final gap interpolates from `early_pattern_spacing` to the normal gap using the ratio of current distance to `early_spacing_end_distance`.

## Testing

Simulation and tuning tests verify:

- All new tuning properties use the approved defaults.
- Pattern spacing begins at `18m`.
- Spacing transitions smoothly during the early run.
- At and beyond `250m`, spacing matches the existing speed-based formula.
- The minimum spacing remains `9m`.
