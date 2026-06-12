# Start Screen Title Design

## Goal

Give the normal start screen a clearer visual hierarchy by showing `DOG RUN` at the same size as the post-run `GAME OVER` heading while keeping supporting instructions smaller.

## Behavior

- Add a separate centered `StartTitleLabel` styled at `44px`.
- Show `DOG RUN` in the title label only on later start screens after the first-launch tutorial has been completed.
- Show `Tap to Start` in the existing overlay label at `30px` below the title.
- On the first launch, hide the title label and continue showing the existing tutorial instructions and `Tap to Start` together at `30px`.
- Hide both start labels while a run is active and on the game-over screen.

## Layout

The title and supporting overlay remain centered around the existing start-screen focus area. The title sits above the supporting text with enough separation to avoid overlap on mobile screens.

## Testing

The active-scene smoke test verifies:

- The later start screen shows `DOG RUN` at `44px`.
- The later start screen shows only `Tap to Start` in the `30px` overlay.
- The first-launch tutorial hides the title and retains the tutorial text at `30px`.
- Both labels hide during active runs and game over.
