# Dog Run V2 Playtest Log

## Automated and Desktop Verification

- Status: automated logic, active-scene smoke, and headless startup checks passing
- Environment: Windows desktop, Godot 4.5.1 Compatibility renderer
- Android export attempt: blocked by missing configured Java SDK and Android SDK paths
- iOS export attempt: blocked by intentionally unset App Store Team ID and requires macOS/Xcode for completion

## Android Session

- Status: pending physical device and Android export prerequisites
- Results: not yet recorded

## iOS Session

- Status: pending macOS, Xcode, signing, and physical device
- Results: not yet recorded

## Residual Risks

- Mobile GPU performance has not yet been measured.
- Safe-area behavior has not yet been observed on a notched physical device.
- Haptic comfort and audio latency require physical-device review.
- Final control tuning requires the structured Android and iOS sessions.
