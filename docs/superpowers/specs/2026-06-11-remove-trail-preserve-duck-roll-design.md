# Remove Trail and Preserve Duck Roll

## Goal

Remove the player speed trail and keep the textured sphere's roll continuous while ducking.

## Design

- Delete the speed-trail particle node, update code, and tuning values.
- Restore the runtime particle-node limit from five to four.
- Store the sphere's roll in `_player_roll_angle`.
- Advance that angle while running and rebuild the mesh basis from the stored angle every frame.
- Keep duck, jump, landing, and lane lean on the parent visual pivot so they cannot reset roll.

## Verification

- The active scene contains no `PlayerSpeedTrail`.
- Particle and tuning regressions confirm all trail configuration is removed.
- A smoke regression ducks during a run and confirms the roll angle advances and the mesh basis matches it.
