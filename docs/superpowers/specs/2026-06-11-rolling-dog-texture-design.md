# Rolling Dog Texture Design

## Goal

Map the supplied dog-face drawing onto the player sphere and let it rotate naturally with the existing rolling animation.

## Asset

Use `assets/player/white.png`, a `512 × 1024` portrait PNG with a pale background.

Because the image is portrait rather than a standard `2:1` spherical texture, preserve its proportions with UV scaling and center it on the front portion of the sphere. Disable texture repetition so the pale image edge fills the remaining circumference instead of repeating the face.

## Rendering

Create a dedicated player `StandardMaterial3D` using the dog texture as its albedo texture. Keep the current roughness, scene lighting, cyan player light, player scale effects, and rolling rotation unchanged.

The sphere starts with the dog face aimed toward the camera. During a run, the existing X-axis rotation causes the face to roll around the sphere.

## Verification

The active-scene smoke test verifies that:

- the player uses the supplied texture
- portrait-preserving UV scale and offset are applied
- texture repetition is disabled
- the running sphere continues to rotate

A portrait render verifies the initial face orientation and visual proportions.

