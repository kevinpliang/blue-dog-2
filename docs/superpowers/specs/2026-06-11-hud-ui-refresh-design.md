# HUD UI Refresh

## Goal

Give the game a cleaner, more focused HUD and a readable aligned post-run summary.

## Typography

Use `assets/fonts/Michroma-Regular.ttf` for every HUD label.

## Start And Tutorial Screens

Hide score, multiplier, and high score. Show only the existing start or tutorial message.

## Running HUD

Show a stacked top-right HUD:

- large score number with no prefix
- smaller cyan multiplier directly beneath it

The multiplier remains visible at `x1`. High score is never shown during a run.

## Post-Run Summary

Hide the running HUD and show:

- `NEW HIGH SCORE` prominently when the run beats the previous high score
- `GAME OVER`
- an aligned two-column grid containing distance, peak multiplier, near misses, score, and high score
- centered `Tap to Restart`

Use Godot containers for alignment across mobile aspect ratios. Track whether the completed run set a new high score before updating the saved value.
