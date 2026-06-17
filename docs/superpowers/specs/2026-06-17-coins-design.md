# Coins Design

## Goal

Add collectible coins that appear as gold coin-shaped 3D objects on the track, rotate slowly, and increase a persisted total coin count immediately when collected.

Coins should make obstacle interactions feel more rewarding by appearing in lanes and heights that encourage jumping, ducking, or choosing the intended opening through a pattern.

## Player Experience

- Coins are visible during runs as bright gold/yellow coin objects on the track.
- Coins rotate slowly so they read as collectible objects rather than obstacles.
- The player's total coin count is shown in the top-left:
  - main menu / ready screen
  - active run
  - game-over screen
- Collected coins are added to the persisted total immediately during the run.
- Coins are not part of score in v1. They are a separate long-term currency/count.

## Placement

Use pattern-authored coin placement for v1.

Each curated obstacle pattern can define optional coins with:

- `offset`: meters after the pattern's first row, matching obstacle-row offset style
- `lane`: `0` left, `1` center, `2` right
- `height`: target player vertical offset for collection

Use three simple coin placement styles:

- Ground/route coins at `height = 0.0` in safe or intended lanes.
- Jump coins at an airborne height, such as `height = 1.15`, placed above ground-block/jump moments.
- Duck coins at `height = 0.0` in lanes guarded by overhead bars, encouraging the player to duck through for the coin.

Patterns do not need coins everywhere. V1 will add coins to at least four tier 0 or tier 1 patterns so coins appear early and teach the mechanic.

## Simulation

`RunnerSimulation` owns run-local coin state:

- Add `coins: Array[Dictionary]`.
- Each coin contains:
  - `id`
  - `pattern_id`
  - `lane`
  - `height`
  - `z`
  - `collected`
- Coins scroll forward using the same travel value as obstacles.
- Coins are removed after passing behind the player.
- A coin is collected when:
  - run state is `RUNNING`
  - coin is not already collected
  - coin Z is close to the player action plane
  - player lane/X is close enough to the coin lane
  - `player_y` is close enough to the coin height
- On collection:
  - mark the coin collected
  - increment `run_coin_count`
  - emit `{"type": "coin_collected", "coin_id": id}`

Coin collection should not affect collision, score, multiplier, near misses, or obstacle clears.

## Persistence and HUD

`Main` owns persisted total coins because it already owns `ConfigFile` persistence and HUD construction.

Persist in `user://dog_run.cfg`:

- `currency/coins`

Existing saves default to `0`.

When `Main` processes a `coin_collected` event from `RunnerSimulation`, it increments `_total_coins` immediately and saves progress right away. This makes collected coins durable even if the app is closed before game over.

HUD behavior:

- Add a top-left coin label, using the existing Michroma HUD style.
- The label displays the persisted total coin count.
- Show it on ready, running, and game-over screens.
- Keep it separate from score/multiplier in the top-right.

## Visuals

Coins should be simple, cheap 3D nodes:

- Use a pooled `MeshInstance3D` set, similar to obstacles.
- Use a flattened cylinder mesh or similarly coin-shaped primitive.
- Use a gold/yellow material with emission.
- Rotate slowly every frame while visible.
- Position with:
  - `x = simulation.lane_x(lane)`
  - `y = 0.75 + height`
  - `z = coin.z + TUNING.visual_action_plane_z`

No custom coin texture, particle burst, or sound cue is required for v1.

## Testing

Simulation tests should cover:

- starting a run clears run-local coins and coin count
- generated patterns can spawn coins with deterministic IDs and positions
- coins scroll with the same travel as obstacles
- collecting a coin increments `run_coin_count` and emits `coin_collected`
- wrong lane or wrong height does not collect a coin
- collected coins are not collected twice

Pattern-library tests should cover:

- authored coin lanes are valid
- authored coin offsets are non-negative
- authored coin heights are non-negative
- at least a few early patterns contain coins

Scene smoke tests should cover:

- coin HUD label exists in the top-left and uses Michroma
- coin HUD label is visible on ready, running, and game-over screens
- total coins persist through save/load
- active scene creates visible coin nodes with gold/emissive material

## Out of Scope for V1

- Spending coins
- Coin pickups affecting score or multiplier
- Coin magnet effects
- Coin sound effects
- Coin collection particles
- Complex coin trails or procedural arcs
