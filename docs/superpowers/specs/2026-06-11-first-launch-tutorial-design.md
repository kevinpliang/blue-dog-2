# First-Launch Tutorial

## Goal

Teach first-time players the four swipe controls without interrupting gameplay.

## Design

On the ready screen, first-time players see:

```text
SWIPE LEFT / RIGHT TO MOVE
SWIPE UP TO JUMP
SWIPE DOWN TO DUCK

Tap to Start
```

The first tap starts the run normally, saves `tutorial_completed = true` in the existing `ConfigFile`, and prevents the tutorial from appearing again. Returning players continue to see the existing `DOG RUN / Tap to Start` message. Gameplay, gestures, obstacles, and restart behavior remain unchanged.
