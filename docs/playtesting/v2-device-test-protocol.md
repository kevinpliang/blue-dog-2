# Dog Run V2 Device Test Protocol

Run this protocol on at least one representative Android device and one iOS device.

## Session Metadata

- Date and build commit
- Device model
- OS version
- Screen resolution and refresh rate
- Debug or release build

## Three-Run Session

For each uninterrupted run, record:

- final score and distance
- peak multiplier and near-miss count
- run duration
- average and worst frame timing
- missed left, right, jump, and duck swipes
- unfair or unreadable death, including run seed when available
- track-fade readability
- sound and haptic comfort
- notes on lane, jump, and duck feel

During one run, background and foreground the app and confirm the run remains paused.

## Pass Criteria

- No visible track endpoint.
- No known generated pattern is unreachable.
- No repeated missed-swipe category remains.
- Target frame rate is sustained during a three-minute run.
- At least one tester completes or nearly completes a three-minute fair run.
- Android and iOS have no lifecycle or safe-area blocker.
- The intentional `0.3s` duck duration and `0.05s` cooldown remain unchanged unless a new explicit decision approves a change.
