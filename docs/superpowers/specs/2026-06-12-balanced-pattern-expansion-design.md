# Balanced Pattern Expansion

## Goal

Add more varied obstacle sequences that balance lane changes, jumps, ducks, route choices, and quick action changes.

## Tier 1 Patterns

- `jump_wall_duck_gate`: one row with a ground block, wall, and overhead bar across the three lanes.
- `duck_wall_jump_gate`: mirrored three-lane action gate.
- `jump_gate_then_left`: a full-width jump row followed by a wall row that routes the player left.
- `duck_gate_then_right`: a full-width duck row followed by a wall row that routes the player right.

## Tier 2 Patterns

- `jump_then_duck_gate`: full-width jump row followed by a full-width duck row after `20m`.
- `duck_then_jump_gate`: full-width duck row followed by a full-width jump row after `9m`.
- `weave_left_center_jump`: wall rows route left then center, followed by a full-width jump row.
- `weave_right_center_duck`: mirrored wall weave followed by a full-width duck row.

## Fairness

- Keep at least `8m` between consecutive wall rows.
- Validate every new pattern at maximum speed.
- Keep airborne ducking out of scope; jump-to-duck spacing allows the player to land first.

